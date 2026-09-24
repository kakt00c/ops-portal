module MunicipalityBoundaryTestHelper
  def create_municipality_boundary(municipality:, district: nil, center_lat:, center_lon:, size: 0.1, boundary_kind: nil)
    min_lon = center_lon - size
    max_lon = center_lon + size
    min_lat = center_lat - size
    max_lat = center_lat + size

    boundary_kind ||= district.present? ? "district" : "municipality"

    wkt = "POLYGON((#{min_lon} #{min_lat}, #{max_lon} #{min_lat}, #{max_lon} #{max_lat}, #{min_lon} #{max_lat}, #{min_lon} #{min_lat}))"

    sql = <<~SQL
      INSERT INTO municipality_boundaries (municipality_id, municipality_district_id, boundary_kind, boundary, created_at, updated_at)
      VALUES (?, ?, ?, ST_SetSRID(ST_GeomFromText(?), 4326), NOW(), NOW())
    SQL

    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql([ sql, municipality&.id, district&.id, boundary_kind, wkt ])
    )

    MunicipalityBoundary.order(:id).last
  end
end
