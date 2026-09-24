class RemoveUniqueIndexFromMunicipalityBoundaries < ActiveRecord::Migration[8.1]
  INDEX_NAME = "index_municipality_boundaries_on_municipality_and_district"

  def up
    remove_index :municipality_boundaries, name: INDEX_NAME if index_exists?(:municipality_boundaries, [ :municipality_id, :municipality_district_id ], name: INDEX_NAME)
  end

  def down
    return if index_exists?(:municipality_boundaries, [ :municipality_id, :municipality_district_id ], name: INDEX_NAME)

    add_index :municipality_boundaries,
              [ :municipality_id, :municipality_district_id ],
              unique: true,
              name: INDEX_NAME
  end
end
