class CreateMunicipalityBoundaries < ActiveRecord::Migration[8.1]
  def change
    create_table :municipality_boundaries do |t|
      t.references :municipality, null: false, foreign_key: true
      t.references :municipality_district, null: true, foreign_key: true
      t.timestamps
    end

    execute <<~SQL
      ALTER TABLE municipality_boundaries
      ADD COLUMN boundary geometry(Geometry, 4326) NOT NULL
    SQL

    execute <<~SQL
      CREATE INDEX index_municipality_boundaries_on_boundary
      ON municipality_boundaries
      USING GIST (boundary)
    SQL
  end
end
