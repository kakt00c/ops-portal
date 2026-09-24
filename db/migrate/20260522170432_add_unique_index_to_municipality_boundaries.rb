class AddUniqueIndexToMunicipalityBoundaries < ActiveRecord::Migration[8.1]
  def change
    add_index :municipality_boundaries,
              [ :municipality_id, :municipality_district_id ],
              unique: true,
              name: "index_municipality_boundaries_on_municipality_and_district"
  end
end
