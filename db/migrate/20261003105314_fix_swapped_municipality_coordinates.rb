class FixSwappedMunicipalityCoordinates < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE municipalities
      SET (latitude, longitude) = (longitude, latitude)
      WHERE latitude IS NOT NULL
        AND longitude IS NOT NULL
        AND latitude BETWEEN 16.0 AND 23.0
        AND longitude BETWEEN 47.0 AND 50.0;
    SQL
  end

  def down
  end
end
