require "test_helper"

class IssuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @issue = issues(:two)
  end

  test "should redirect responsible subject user to responsible subject issues" do
    user = users(:responsible_subject)

    post email_auth_request_path, params: { email: user.email }
    assert_response :redirect

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    key = email.body.encoded.match(/key=([^"&]+)/)[1]

    post "/email-auth", params: { key: key }
    assert_response :redirect
    follow_redirect!

    get relevant_issues_url

    assert_redirected_to issues_url(zodpovedny: user.responsible_subject.subject_name)
  end

  test "should redirect citizen user to municipality issues" do
    user = users(:one)

    post "/login", params: { email: user.email, password: "password" }
    assert_response :redirect

    get relevant_issues_url

    assert_redirected_to issues_url(obec: user.municipality.name)
  end

  test "should redirect anonymous user to all issues" do
    get relevant_issues_url

    assert_redirected_to issues_url
  end

  test "last visited municipality is remembered for relevant issues" do
    get issues_url(obec: "Nitra", cast: "")
    get relevant_issues_url

    assert_redirected_to issues_url(obec: "Nitra", cast: nil)
  end

  test "should ignore filter params of unexpected shape" do
    get "/dopyty?kategoria[foo]=bar&obec[foo]=bar&podkategoria[0][x]=y&q[a]=b"
    assert_response :success
    assert_nil session[:last_municipality]
  end

  test "should not show resolved_private issues" do
    get issue_url(issues(:resolved_private))
    assert_response :not_found
  end

  # map data

  test "geo returns clustered issues inside the bounding box as GeoJSON" do
    inside = issues(:two)
    inside.update_columns(latitude: 48.1486, longitude: 17.1077)
    outside = issues(:legacy1)
    outside.update_columns(latitude: 48.7164, longitude: 21.2611)

    get geo_issues_url(bbox: "16.9,48.0,17.3,48.3", z: 12, format: :json)

    assert_response :success
    body = response.parsed_body
    assert_equal "FeatureCollection", body["type"]
    assert_equal 1, body["features"].size

    feature = body["features"].first
    assert_equal "Feature", feature["type"]
    assert_equal "Point", feature.dig("geometry", "type")
    assert_in_delta 17.1077, feature.dig("geometry", "coordinates", 0)
    assert_equal 1, feature.dig("properties", "count")
    assert_equal inside.title, feature.dig("properties", "title")
    assert_equal issue_url(inside), feature.dig("properties", "url")
  end

  test "geo groups nearby issues into one cluster at low zoom" do
    issues(:two).update_columns(latitude: 48.1486, longitude: 17.1077)
    issues(:legacy1).update_columns(latitude: 48.1490, longitude: 17.1080)

    get geo_issues_url(bbox: "16.9,48.0,17.3,48.3", z: 5, format: :json)

    feature = response.parsed_body["features"].first
    assert_equal 1, response.parsed_body["features"].size
    assert_equal 2, feature.dig("properties", "count")
    assert feature.dig("properties").key?("min_latitude")
    assert_nil feature.dig("properties", "title")
  end

  # location filters (obec + cast, pin, oblast) are mutually exclusive

  test "moja poloha link drops all location filters and keeps the others" do
    get issues_url(obec: [ "Bratislava" ], cast: [ "Staré Mesto" ], oblast: "17.0,48.0,17.3,48.3", q: "osvetlenie", sort: "oblubene")

    url = css_select("[data-geolocate-url-value]").first["data-geolocate-url-value"]

    assert_equal %w[ q sort ], query_params(url).keys.sort
  end

  test "obec links drop pin and oblast and keep the other filters" do
    get issues_url(pin: "48.1486,17.1077", oblast: "17.0,48.0,17.3,48.3", q: "osvetlenie", sort: "oblubene")

    hrefs = obec_and_cast_links
    assert hrefs.any?

    hrefs.each do |href|
      params = query_params(href)
      assert_not params.key?("pin"), href
      assert_not params.key?("oblast"), href
      assert_equal "osvetlenie", params["q"], href
      assert_equal "oblubene", params["sort"], href
    end
  end

  test "cast links drop pin and oblast and keep the obec" do
    get issues_url(obec: [ "Bratislava" ], pin: "48.1486,17.1077", oblast: "17.0,48.0,17.3,48.3")

    hrefs = obec_and_cast_links.select { |href| query_params(href).key?("cast") }
    assert hrefs.any?

    hrefs.each do |href|
      params = query_params(href)
      assert_equal [ "Bratislava" ], params["obec"], href
      assert_not params.key?("pin"), href
      assert_not params.key?("oblast"), href
    end
  end

  test "map area search drops obec, cast and pin and keeps the other filters" do
    issues(:two).update_columns(latitude: 48.1486, longitude: 17.1077)

    get issues_url(tab: "map", obec: [ "Bratislava" ], pin: "48.1486,17.1077", sort: "oblubene")

    url = css_select("[data-search-map-base-search-url-value]").first["data-search-map-base-search-url-value"]

    assert_equal({ "sort" => "oblubene", "tab" => "list" }, query_params(url))
  end

  private

  def query_params(url)
    Rack::Utils.parse_nested_query(URI.parse(url).query)
  end

  def obec_and_cast_links
    css_select("a[href]").map { _1["href"] }.select do |href|
      href.start_with?("/dopyty?") && (query_params(href).keys & %w[ obec cast ]).any?
    end
  end
end
