module OverpassClient
  extend self

  DEFAULT_ENDPOINT = "https://overpass-api.de/api/interpreter"

  # Fetches all Slovak municipalities as GeoJSON via Overpass API.
  # Uses admin_level=8 for most towns, but also admin_level=5 for
  # Bratislava/Košice because those are tagged at level 5 in OSM.
  def fetch_municipalities_geojson(country_code: "SK")
    query = <<~QL
      [out:json][timeout:300];
      area["ISO3166-1:alpha2"="#{country_code}"]->.country;
      (
        rel(area.country)["boundary"="administrative"]["admin_level"="8"];
        rel(area.country)["boundary"="administrative"]["admin_level"="5"];
      );
      out body;
      >;
      out skel qt;
    QL

    response = post_query(query)
    OverpassGeoJsonConverter.to_geojson(response)
  end

  # Fetches district (cadastral community) boundaries for a given municipality.
  # Uses `map_to_area` to find the municipality's interior relations at
  # admin_level=10. Returns nil if no districts are found.
  def fetch_districts_geojson(municipality_name:, admin_level: 8)
    query = <<~QL
      [out:json][timeout:120];
      rel["name"="#{escape_quote(municipality_name)}"]["admin_level"="#{admin_level}"]->.muni;
      .muni map_to_area->.a;
      rel(area.a)["boundary"="administrative"]["admin_level"="10"];
      out body;
      >;
      out skel qt;
    QL

    response = post_query(query)
    geojson = OverpassGeoJsonConverter.to_geojson(response)

    geojson if geojson["features"].any?
  end

  private

  def post_query(query)
    response = client.post("", "data=#{CGI.escape(query)}")
    raise "Overpass error: HTTP #{response.status}" unless response.success?

    body = response.body
    if body.is_a?(String)
      JSON.parse(body)
    else
      body
    end
  rescue JSON::ParserError => e
    raise "Overpass returned non-JSON: #{e.message}"
  end

  def client
    @client ||= Faraday.new(
      url: DEFAULT_ENDPOINT,
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
        "User-Agent" => "www.odkazprestarostu.sk"
      }
    ) do |f|
      f.adapter :net_http
    end
  end

  def escape_quote(str)
    str.gsub('"', '\\"')
  end
end
