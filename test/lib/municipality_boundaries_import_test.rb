require "test_helper"

load Rails.root.join("lib/tasks/municipality_boundaries_import.rake")

class MunicipalityBoundariesImportTest < ActiveSupport::TestCase
  setup do
    MunicipalityBoundary.delete_all
  end

  test "find_municipality can match a municipality by coordinates inside geometry" do
    municipality = municipalities("Piešťany")

    geometry = square_geometry(
      center_lat: municipality_real_latitude(municipality),
      center_lon: municipality_real_longitude(municipality),
      size: 0.001
    )

    assert_equal municipality, send(:find_municipality, {}, geometry: geometry, allow_location_match: true)
  end

  test "connect_municipality_boundaries_by_location assigns staged municipality boundaries" do
    municipality = municipalities("Piešťany")
    boundary = create_municipality_boundary(
      municipality: nil,
      center_lat: municipality_real_latitude(municipality),
      center_lon: municipality_real_longitude(municipality),
      size: 0.001,
      boundary_kind: "municipality"
    )

    assert_nil boundary.municipality

    matched, unmatched, ambiguous = send(:connect_municipality_boundaries_by_location)

    assert_equal [ 1, 0, 0 ], [ matched, unmatched, ambiguous ]
    assert_equal municipality, boundary.reload.municipality
  end

  test "district import matches by name only when geometry intersects municipality boundary" do
    municipality = municipalities("bratislava")
    district = municipality_districts("stare_mesto_ba")
    municipality_boundary = create_municipality_boundary(
      municipality: municipality,
      center_lat: municipality_real_latitude(municipality),
      center_lon: municipality_real_longitude(municipality),
      size: 0.02,
      boundary_kind: "municipality"
    )

    imported, skipped = send(
      :import_features,
      [ district_feature(name: district.name, center_lat: 0.0, center_lon: 0.0, size: 0.001) ],
      municipality: municipality,
      municipality_boundary: municipality_boundary,
      municipality_hint: municipality.name,
      import_mode: :districts
    )

    assert_equal [ 1, 0 ], [ imported, skipped ]

    imported_boundary = MunicipalityBoundary.district_boundaries.order(:id).last
    assert_equal municipality, imported_boundary.municipality
    assert_nil imported_boundary.municipality_district
  end

  test "district import stores unmatched district boundaries for later manual matching" do
    municipality = municipalities("bratislava")
    municipality_boundary = create_municipality_boundary(
      municipality: municipality,
      center_lat: municipality_real_latitude(municipality),
      center_lon: municipality_real_longitude(municipality),
      size: 0.02,
      boundary_kind: "municipality"
    )

    imported, skipped = send(
      :import_features,
      [ district_feature(name: "Unknown District", center_lat: municipality_real_latitude(municipality), center_lon: municipality_real_longitude(municipality), size: 0.001) ],
      municipality: municipality,
      municipality_boundary: municipality_boundary,
      municipality_hint: municipality.name,
      import_mode: :districts
    )

    assert_equal [ 1, 0 ], [ imported, skipped ]

    imported_boundary = MunicipalityBoundary.district_boundaries.order(:id).last
    assert_equal municipality, imported_boundary.municipality
    assert_nil imported_boundary.municipality_district
  end

  private

  def district_feature(name:, center_lat:, center_lon:, size: 0.1)
    {
      "properties" => { "name" => name },
      "geometry" => square_geometry(center_lat: center_lat, center_lon: center_lon, size: size)
    }
  end

  def square_geometry(center_lat:, center_lon:, size: 0.1)
    min_lon = center_lon - size
    max_lon = center_lon + size
    min_lat = center_lat - size
    max_lat = center_lat + size

    {
      "type" => "Polygon",
      "coordinates" => [
        [
          [ min_lon, min_lat ],
          [ max_lon, min_lat ],
          [ max_lon, max_lat ],
          [ min_lon, max_lat ],
          [ min_lon, min_lat ]
        ]
      ]
    }
  end

  def municipality_real_latitude(municipality)
    municipality.longitude
  end

  def municipality_real_longitude(municipality)
    municipality.latitude
  end
end
