module OsmClient
  extend self

  AddressDetails = Struct.new(:house_number, :street, :suburb, :municipality, :district, :city, :postcode, :region, :country, :country_code, :data)

  def get_address_details(lat:, lon:, downloader: default_downloader)
    details = fetch_osm_details(lat, lon, downloader: downloader)

    build_address_details(details)
  end

  def build_address_details(details)
    address = details["address"]
    address = address.sort { |a, b| a["rank_address"] <=> b["rank_address"] } if address.is_a?(Array)
    administratives = address.select { it["type"] == "administrative" }
    place_settlements = address.select { it["class"] == "place" && [ "city", "town", "village", "municipality" ].include?(it["type"]) }

    level_9 = administratives.select { it["admin_level"] == 9 }
    level_8 = administratives.select { it["admin_level"] == 8 }
    municipality = level_9.find { _1["isaddress"] }&.dig("localname")
    municipality ||= level_9.first&.dig("localname")
    municipality ||= level_8.find { _1["isaddress"] }&.dig("localname")
    municipality ||= level_8.first&.dig("localname")
    municipality ||= place_settlements.find { _1["isaddress"] }&.dig("localname")
    municipality ||= place_settlements.first&.dig("localname")

    suburb = administratives.find { _1["admin_level"] == 10 }&.dig("localname")
    suburb ||= address.select { it["type"] == "suburb" }&.select { _1["admin_level"] == 15 }&.find { _1["isaddress"] }&.dig("localname")

    if municipality.present? && suburb.present? && municipality == suburb
      municipality = level_8.find { _1["localname"] != suburb }&.dig("localname") || municipality
    end

    city = place_settlements.find { _1["isaddress"] }&.dig("localname")
    city ||= place_settlements.first&.dig("localname")
    city ||= level_8.find { _1["isaddress"] }&.dig("localname")
    city ||= level_8.first&.dig("localname")
    city ||= municipality

    AddressDetails.new(
      house_number: address.find { _1["type"] == "house_number" }&.dig("localname"),
      street: address.find { _1["class"] == "highway" }&.dig("localname"),
      suburb: suburb,
      municipality: municipality,
      district: administratives.find { _1["admin_level"] == 8 }&.dig("localname"),
      city: city,
      postcode: address.find { _1["type"] == "postcode" }&.dig("localname"),
      region: administratives.find { _1["admin_level"] == 4 }&.dig("localname"),
      country: address.find { _1["type"] == "country" }&.dig("localname"),
      country_code: address.find { _1["type"] == "country_code" }&.dig("localname"),
      data: details
    )
  end

  def fetch_and_write_to_file(lat, lon, file_path, downloader: default_downloader)
    details = fetch_osm_details(lat, lon, downloader: downloader)
    File.write(file_path, JSON.pretty_generate(details))
  end

  # private

  def fetch_osm_details(lat, lon, downloader: default_downloader)
    response = downloader.get("/reverse", { lat: lat, lon: lon, format: :json })
    json = response.body

    osmtype = case json["osm_type"]
    when "way"
        "W"
    when "node"
        "N"
    when "relation"
        "R"
    else
        raise NotImplementedError, "Unknown osm_type: #{json["osm_type"]}"
    end
    response = downloader.get("/details", { format: :json, osmtype: osmtype, osmid: json["osm_id"], addressdetails: 1 })
    response.body
  end

  def default_downloader
    Faraday.new(
      url: "https://nominatim.openstreetmap.org",
      headers: {
        "content-type": "application/json",
        "User-Agent": "www.odkazprestarostu.sk",
        "Accept-Language": "sk"
      }
    ) do |f|
      f.adapter :patron
      f.response :json
    end
  end
end
