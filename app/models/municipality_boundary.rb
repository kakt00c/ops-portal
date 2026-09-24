# == Schema Information
#
# Table name: municipality_boundaries
#
#  id                       :bigint           not null, primary key
#  boundary                 :geometry(Geometr not null
#  boundary_kind            :string           default("municipality"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  municipality_district_id :bigint
#  municipality_id          :bigint
#
class MunicipalityBoundary < ApplicationRecord
  belongs_to :municipality, optional: true
  belongs_to :municipality_district, optional: true

  scope :district_boundaries, -> { where(boundary_kind: "district") }
  scope :districts, -> { district_boundaries.where.not(municipality_district_id: nil) }
  scope :municipalities, -> { where(boundary_kind: "municipality").where.not(municipality_id: nil) }
  scope :unmatched_municipalities, -> { where(boundary_kind: "municipality", municipality_id: nil) }
  scope :unmatched_districts, -> { district_boundaries.where(municipality_district_id: nil) }

  scope :containing_point, ->(latitude, longitude) {
    where(
      "ST_Covers(boundary, ST_SetSRID(ST_MakePoint(?, ?), 4326))",
      longitude, latitude
    )
  }
end
