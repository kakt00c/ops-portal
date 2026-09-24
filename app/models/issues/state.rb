# == Schema Information
#
# Table name: issues_states
#
#  id         :bigint           not null, primary key
#  color      :string
#  key        :string
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  legacy_id  :integer
#
class Issues::State < ApplicationRecord
  PRIVATE_KEYS = %w[waiting waiting_for_author rejected resolved_private duplicate]

  scope :not_visible, -> { where(key: PRIVATE_KEYS) }
  scope :archived, -> { where(key: "archived") }
end
