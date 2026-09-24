class RequireMunicipalityOnIssues < ActiveRecord::Migration[8.0]
  def change
    change_column_null :issues, :municipality_id, false
  end
end
