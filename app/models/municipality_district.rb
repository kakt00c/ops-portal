# == Schema Information
#
# Table name: municipality_districts
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(FALSE)
#  aliases         :string           default([]), not null, is an Array
#  archived        :boolean          default(FALSE)
#  description     :string
#  genitiv         :string
#  logo            :string
#  lokal           :string
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  legacy_id       :integer
#  municipality_id :bigint           not null
#
class MunicipalityDistrict < ApplicationRecord
  belongs_to :municipality
  has_many :streets, dependent: :nullify
  has_many :issues
  has_many :municipality_boundaries

  scope :archived, -> { where(archived: true) }
  scope :active, -> { where(active: true) }
end
