# == Schema Information
#
# Table name: responsible_subjects
#
#  id                           :bigint           not null, primary key
#  active                       :boolean
#  code                         :string
#  email                        :string
#  name                         :string
#  pro                          :boolean
#  scope                        :integer
#  subject_name                 :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  district_id                  :bigint
#  external_id                  :string
#  legacy_id                    :integer
#  municipality_district_id     :bigint
#  municipality_id              :bigint
#  responsible_subjects_type_id :bigint           not null
#
class ResponsibleSubject < ApplicationRecord
  has_many :categories, class_name: "ResponsibleSubjects::Category"
  has_many :issues
  has_many :clients
  belongs_to :responsible_subjects_type, optional: true, class_name: "ResponsibleSubjects::Type"
  belongs_to :district, optional: true
  belongs_to :municipality, optional: true
  belongs_to :municipality_district, optional: true

  scope :active, -> { where(active: true) }
  scope :archived, -> { where(active: false) }

  def archived?
    active == false
  end

  def self.search(query)
    where("unaccent(lower(subject_name)) LIKE unaccent(lower(?))", "#{query}%").or(
      where("unaccent(lower(subject_name)) LIKE unaccent(lower(?))", "% #{query}%")
    )
  end
end
