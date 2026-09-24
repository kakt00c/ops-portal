module OverpassGeoJsonConverter
  extend self

  # Converts an Overpass API JSON response (with nodes, ways, relations)
  # into a GeoJSON FeatureCollection containing Polygon / MultiPolygon features.
  def to_geojson(overpass_response)
    elements = overpass_response["elements"] || []

    nodes = elements.each_with_object({}) do |el, hash|
      hash[el["id"]] = el if el["type"] == "node"
    end

    ways = elements.each_with_object({}) do |el, hash|
      hash[el["id"]] = el if el["type"] == "way"
    end

    relations = elements.select { |el| el["type"] == "relation" }

    features = relations.filter_map do |rel|
      geometry = build_relation_geometry(rel, nodes, ways)
      next unless geometry

      {
        "type" => "Feature",
        "properties" => rel["tags"] || {},
        "geometry" => geometry
      }
    end

    {
      "type" => "FeatureCollection",
      "features" => features
    }
  end

  private

  def build_relation_geometry(relation, nodes, ways)
    outer_rings = []
    inner_rings = []

    members = relation["members"] || []
    members.each do |member|
      next unless member["type"] == "way"

      way = ways[member["ref"]]
      next unless way

      ring = way_to_ring(way, nodes)
      next if ring.nil? || ring.size < 2

      case member["role"]
      when "outer"
        outer_rings << ring
      when "inner"
        inner_rings << ring
      else
        outer_rings << ring
      end
    end

    merged_outer_rings = merge_rings(outer_rings)
    return nil if merged_outer_rings.empty?

    merged_inner_rings = merge_rings(inner_rings)

    polygon_parts = merged_outer_rings.map do |outer_ring|
      [ outer_ring ] + merged_inner_rings.select { |inner_ring| ring_inside?(inner_ring, outer_ring) }
    end

    if polygon_parts.one?
      { "type" => "Polygon", "coordinates" => polygon_parts.first }
    else
      { "type" => "MultiPolygon", "coordinates" => polygon_parts }
    end
  end

  def way_to_ring(way, nodes)
    (way["nodes"] || []).map do |node_id|
      node = nodes[node_id]
      next unless node

      [ node["lon"], node["lat"] ]
    end.compact
  end

  # Merge relation member ways into closed rings.
  def merge_rings(rings)
    pending = rings.map(&:dup)
    merged_rings = []

    until pending.empty?
      ring = pending.shift

      loop do
        break if closed_ring?(ring)

        matching_index = pending.find_index { |candidate| rings_connect?(ring, candidate) }
        break unless matching_index

        candidate = pending.delete_at(matching_index)
        ring = join_rings(ring, candidate)
      end

      merged_rings << ring if closed_ring?(ring)
    end

    merged_rings
  end

  def rings_connect?(a, b)
    a.last == b.first || a.last == b.last || a.first == b.last || a.first == b.first
  end

  def join_rings(a, b)
    if a.last == b.first
      a + b[1..]
    elsif a.last == b.last
      a + b.reverse[1..]
    elsif a.first == b.last
      b[0..-2] + a
    elsif a.first == b.first
      b.reverse[0..-2] + a
    else
      a
    end
  end

  def closed_ring?(ring)
    ring.size >= 4 && ring.first == ring.last
  end

  def ring_inside?(inner_ring, outer_ring)
    point = ring_centroid(inner_ring)
    point_in_polygon?(point, outer_ring)
  end

  def ring_centroid(ring)
    lons = ring.map(&:first)
    lats = ring.map(&:last)
    [ lons.sum / lons.size, lats.sum / lats.size ]
  end

  def point_in_polygon?(point, polygon)
    x, y = point
    inside = false
    polygon.each_cons(2) do |(x1, y1), (x2, y2)|
      if ((y1 > y) != (y2 > y)) && (x < (x2 - x1) * (y - y1) / (y2 - y1) + x1)
        inside = !inside
      end
    end
    inside
  end
end
