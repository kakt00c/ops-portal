class AddBoundaryKindToMunicipalityBoundaries < ActiveRecord::Migration[8.1]
  def up
    add_column :municipality_boundaries, :boundary_kind, :string, null: false, default: "municipality"

    execute <<~SQL
      UPDATE municipality_boundaries
      SET boundary_kind = 'district'
      WHERE municipality_district_id IS NOT NULL
    SQL
  end

  def down
    remove_column :municipality_boundaries, :boundary_kind
  end
end
