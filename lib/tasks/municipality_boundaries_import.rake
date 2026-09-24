require "json"
require "cgi"

namespace :municipality_boundaries do
  desc "Download and import all Slovak municipality boundaries from Overpass API"
  task download_and_import_municipalities: :environment do
    unless File.exist?("tmp/municipalities.geojson")
      puts "No local municipalities.geojson file found. Downloading from Overpass API..."
      puts "Downloading municipalities from Overpass API (this may take 1-2 minutes)..."
      geojson = OverpassClient.fetch_municipalities_geojson
      File.write("tmp/municipalities.geojson", JSON.pretty_generate(geojson)) # Save a copy of the downloaded data for reference/debugging
    else
      puts "Using local municipalities.geojson file..."
      geojson = JSON.parse(File.read("tmp/municipalities.geojson"))
    end

    features = geojson["features"] || []
    puts "Got #{features.count} features. Resetting municipality boundaries..."

    MunicipalityBoundary.where(boundary_kind: "municipality").delete_all

    puts "Importing municipality boundaries..."

    imported, skipped = import_features(features, import_mode: :municipalities)
    matched, unmatched, ambiguous = connect_municipality_boundaries_by_location

    puts "Done. Imported: #{imported}, Skipped: #{skipped}, Matched: #{matched}, Unmatched: #{unmatched}, Ambiguous: #{ambiguous}"
  end

  desc "Download and import district boundaries for municipalities that have districts"
  task download_and_import_districts: :environment do
    municipalities_with_districts = Municipality.joins(:municipality_districts).distinct
    total = municipalities_with_districts.count

    puts "Found #{total} municipalities with districts. Downloading from Overpass API..."

    imported_total = 0
    skipped_total = 0

    municipalities_with_districts.find_each.with_index do |municipality, idx|
      puts "\n[#{idx + 1}/#{total}] #{municipality.name}"

      MunicipalityBoundary.district_boundaries.where(municipality: municipality).delete_all

      municipality_boundary = MunicipalityBoundary.municipalities.find_by(municipality: municipality)

      unless municipality_boundary
        puts "  -> Municipality boundary missing for #{municipality.name}. District boundaries will be imported unmatched."
      end

      # Determine OSM admin_level for the municipality.
      # Bratislava and Košice are admin_level=5, everything else is 8.
      admin_level = %w[Bratislava Košice].include?(municipality.name) ? 5 : 8

      geojson = OverpassClient.fetch_districts_geojson(
        municipality_name: municipality.name,
        admin_level: admin_level
      )

      if geojson.nil?
        puts "  -> No district data found in OSM for #{municipality.name} (admin_level=#{admin_level})"
        next
      end

      features = geojson["features"] || []
      imported, skipped = import_features(
        features,
        municipality: municipality,
        municipality_boundary: municipality_boundary,
        municipality_hint: municipality.name,
        silent: true,
        import_mode: :districts
      )
      imported_total += imported
      skipped_total += skipped

      puts "  -> Imported: #{imported}, Skipped: #{skipped}"

      # Be nice to the Overpass servers — wait 2s between requests.
      sleep 2 unless idx >= total - 1
    end

    puts "\nDone. Total imported: #{imported_total}, Total skipped: #{skipped_total}"
  end

  desc "Download and import all municipality and district boundaries from Overpass API"
  task import_all: :environment do
    puts "=== Step 1: Import municipalities ==="
    Rake::Task["municipality_boundaries:download_and_import_municipalities"].invoke

    puts "\n=== Step 2: Import districts ==="
    Rake::Task["municipality_boundaries:download_and_import_districts"].invoke

    puts "\n=== All done ==="
  end

  desc "Match imported municipality boundaries to municipalities by GPS coordinates"
  task match_municipalities_by_location: :environment do
    matched, unmatched, ambiguous = connect_municipality_boundaries_by_location

    puts "Done. Matched: #{matched}, Unmatched: #{unmatched}, Ambiguous: #{ambiguous}"
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def import_features(features, municipality: nil, municipality_boundary: nil, municipality_hint: nil, silent: false, import_mode: :auto)
    imported = 0
    skipped = 0

    features.each do |feature|
      properties = feature["properties"] || {}
      geometry = feature["geometry"]

      unless geometry
        puts "Skipping feature without geometry: #{properties.inspect}" unless silent
        skipped += 1
        next
      end

      if import_mode == :municipalities
        import_boundary(nil, nil, geometry, boundary_kind: "municipality")
        imported += 1
        next
      end

      if import_mode == :districts
        district = nil

        if municipality_boundary.present? && geometry_intersects_boundary?(geometry, municipality_boundary)
          district = find_municipality_district(
            properties,
            municipality: municipality,
            municipality_hint: municipality_hint || ENV["MUNICIPALITY"]
          )
        end

        import_boundary(municipality, district, geometry, boundary_kind: "district")
        imported += 1
        next
      end

      municipality = find_municipality(properties)
      district = nil

      if municipality
        import_boundary(municipality, district, geometry, boundary_kind: "municipality")
        imported += 1
        next
      end

      district = find_municipality_district(properties, municipality_hint: municipality_hint || ENV["MUNICIPALITY"])

      if district
        import_boundary(district.municipality, district, geometry, boundary_kind: "district")
        imported += 1
      else
        unless silent
          puts "Skipping feature - no municipality/district match: #{properties.inspect}"
        end
        skipped += 1
      end
    end

    puts "Done. Imported: #{imported}, Skipped: #{skipped}" unless silent
    [ imported, skipped ]
  end

  def find_municipality(properties, geometry: nil, allow_location_match: false)
    if allow_location_match && geometry.present?
      municipalities = municipalities_inside_geometry(geometry).to_a
      return municipalities.first if municipalities.one?

      if municipalities.many?
        puts "  Warning: geometry matched multiple municipalities: #{municipalities.map(&:name).join(", ")}"
      end
    end

    if properties["municipality_name"].present?
      municipality = Municipality.find_by(name: properties["municipality_name"])
      return municipality if municipality
    end

    if properties["municipality_legacy_id"].present?
      municipality = Municipality.find_by(legacy_id: properties["municipality_legacy_id"])
      return municipality if municipality
    end

    name_keys = %w[name NAME Name nazov NAZOV Nazov localname LOCALNAME LocalName]
    name_keys.each do |key|
      next unless properties[key].present?

      municipality = Municipality.find_by(name: properties[key])
      return municipality if municipality
    end
  end

  def find_municipality_district(properties, municipality: nil, municipality_hint: nil)
    name = nil
    name_keys = %w[name NAME Name nazov NAZOV Nazov localname LOCALNAME LocalName]
    name_keys.each do |key|
      if properties[key].present?
        name = properties[key]
        break
      end
    end

    return nil if name.blank?

    municipality ||= Municipality.find_by(name: municipality_hint) if municipality_hint.present?

    if municipality
      district = municipality.municipality_districts.find_by(name: name)
      return district if district
    end

    districts = MunicipalityDistrict.where(name: name).to_a
    return districts.first if districts.size == 1

    if districts.size > 1
      puts "  Warning: ambiguous district name '#{name}' found in #{districts.map { "#{_1.municipality.name}::#{_1.name}" }.join(", ")} — use MUNICIPALITY='...' to disambiguate"
    end

    nil
  end

  def connect_municipality_boundaries_by_location
    matched = 0
    unmatched = 0
    ambiguous = 0

    MunicipalityBoundary.unmatched_municipalities.find_each do |boundary|
      municipalities = municipalities_inside_boundary(boundary).to_a

      if municipalities.one?
        boundary.update_columns(municipality_id: municipalities.first.id, updated_at: Time.current)
        matched += 1
      elsif municipalities.empty?
        unmatched += 1
      else
        puts "  Warning: boundary ##{boundary.id} matched multiple municipalities: #{municipalities.map(&:name).join(", ")}"
        ambiguous += 1
      end
    end

    [ matched, unmatched, ambiguous ]
  end

  def geometry_intersects_boundary?(geometry, boundary)
    sql = <<~SQL
      SELECT EXISTS (
        SELECT 1
        FROM municipality_boundaries mb
        WHERE mb.id = ?
          AND ST_Intersects(
            mb.boundary,
            ST_SetSRID(ST_GeomFromGeoJSON(?), 4326)
          )
      ) AS intersects
    SQL

    ActiveRecord::Base.connection.exec_query(
      ActiveRecord::Base.sanitize_sql([ sql, boundary.id, geometry.to_json ])
    ).first["intersects"]
  end

  def municipalities_inside_geometry(geometry)
    Municipality.where.not(latitude: nil)
      .where.not(longitude: nil)
      .where(
        <<~SQL,
          ST_Covers(
            ST_SetSRID(ST_GeomFromGeoJSON(?), 4326),
            #{municipality_location_point_sql}
          )
        SQL
        geometry.to_json
      )
  end

  def municipalities_inside_boundary(boundary)
    Municipality.where.not(latitude: nil)
      .where.not(longitude: nil)
      .where(
        <<~SQL,
          EXISTS (
            SELECT 1
            FROM municipality_boundaries mb
            WHERE mb.id = ?
              AND ST_Covers(
                mb.boundary,
                #{municipality_location_point_sql}
              )
          )
        SQL
        boundary.id
      )
  end

  def municipality_location_point_sql
    # Municipality rows currently store longitude in `latitude` and latitude in `longitude`.
    "ST_SetSRID(ST_MakePoint(municipalities.latitude, municipalities.longitude), 4326)"
  end

  def import_boundary(municipality, district, geometry, boundary_kind:)
    geometry_json = geometry.to_json

    sql = <<~SQL
      INSERT INTO municipality_boundaries (municipality_id, municipality_district_id, boundary_kind, boundary, created_at, updated_at)
      VALUES (?, ?, ?, ST_SetSRID(ST_GeomFromGeoJSON(?), 4326), NOW(), NOW())
      ON CONFLICT DO NOTHING
    SQL

    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql([
        sql,
        municipality&.id,
        district&.id,
        boundary_kind,
        geometry_json
      ])
    )
  end
end
