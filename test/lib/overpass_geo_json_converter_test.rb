require "test_helper"

class OverpassGeoJsonConverterTest < ActiveSupport::TestCase
  test "to_geojson joins split outer ways into a valid polygon ring" do
    overpass_response = {
      "elements" => [
        { "type" => "node", "id" => 1, "lon" => 0.0, "lat" => 0.0 },
        { "type" => "node", "id" => 2, "lon" => 1.0, "lat" => 0.0 },
        { "type" => "node", "id" => 3, "lon" => 1.0, "lat" => 1.0 },
        { "type" => "node", "id" => 4, "lon" => 0.0, "lat" => 1.0 },
        { "type" => "way", "id" => 10, "nodes" => [ 1, 2, 3 ] },
        { "type" => "way", "id" => 11, "nodes" => [ 3, 4, 1 ] },
        {
          "type" => "relation",
          "id" => 100,
          "members" => [
            { "type" => "way", "ref" => 10, "role" => "outer" },
            { "type" => "way", "ref" => 11, "role" => "outer" }
          ],
          "tags" => { "name" => "Test Municipality" }
        }
      ]
    }

    geojson = OverpassGeoJsonConverter.to_geojson(overpass_response)

    assert_equal 1, geojson["features"].size
    assert_equal "Polygon", geojson.dig("features", 0, "geometry", "type")
    assert_equal(
      [
        [ 0.0, 0.0 ],
        [ 1.0, 0.0 ],
        [ 1.0, 1.0 ],
        [ 0.0, 1.0 ],
        [ 0.0, 0.0 ]
      ],
      geojson.dig("features", 0, "geometry", "coordinates", 0)
    )
  end
end
