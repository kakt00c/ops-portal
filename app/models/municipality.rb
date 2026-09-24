# == Schema Information
#
# Table name: municipalities
#
#  id                         :bigint           not null, primary key
#  active                     :boolean
#  active_on_old_portal       :boolean          default(FALSE), not null
#  aliases                    :string           default([]), not null, is an Array
#  archived                   :boolean          default(FALSE)
#  category                   :integer
#  email                      :string
#  handled_by                 :integer
#  has_municipality_districts :boolean
#  languages                  :string
#  latitude                   :float
#  logo                       :string
#  longitude                  :float
#  municipality_type          :integer
#  name                       :string
#  population                 :integer
#  sub                        :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  district_id                :bigint
#  legacy_id                  :integer
#
class Municipality < ApplicationRecord
  belongs_to :district, optional: true
  has_many :municipality_districts
  has_many :streets
  has_many :issues
  has_many :municipality_boundaries

  scope :active, -> { where(active: true) }
  scope :archived, -> { where(archived: true) }

  enum :municipality_type, huge: 2, other: 1
  enum :category, regional_capital: 1, town: 2, village: 3 # TODO Pomenovanie ciselnych hodnot iba podla nasho usudku

  def whitelisted_street?(name)
    streets.whitelisted.find_by_name(name).present?
  end

  def self.find_by_coordinates(latitude, longitude, street: nil)
    return [ nil, nil ] if latitude.blank? || longitude.blank?

    district_boundary = MunicipalityBoundary.districts
      .containing_point(latitude, longitude)
      .first

    if district_boundary
      district = district_boundary.municipality_district
      municipality = district.municipality
      return [ municipality, district ] if municipality.active? && district.active?

      if street.present? && municipality.whitelisted_street?(street)
        return [ municipality, district ]
      end

      return [ nil, district ]
    end

    municipality_boundary = MunicipalityBoundary.municipalities
      .containing_point(latitude, longitude)
      .first

    if municipality_boundary
      municipality = municipality_boundary.municipality
      return [ municipality, nil ] if municipality&.active?
    end

    [ nil, nil ]
  end
end
