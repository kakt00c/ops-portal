class MakeMunicipalityIdNullableOnMunicipalityBoundaries < ActiveRecord::Migration[8.1]
  def change
    change_column_null :municipality_boundaries, :municipality_id, true
  end
end
