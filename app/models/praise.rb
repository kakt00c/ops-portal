# == Schema Information
#
# Table name: issues
#
#  id                                  :bigint           not null, primary key
#  address_city                        :string
#  address_country                     :string
#  address_country_code                :string
#  address_district                    :string
#  address_house_number                :string
#  address_municipality                :string
#  address_postcode                    :string
#  address_region                      :string
#  address_street                      :string
#  address_suburb                      :string
#  anonymous                           :boolean
#  comments_count                      :integer          default(0), not null
#  description                         :string           not null
#  discussion_closed                   :boolean          default(FALSE)
#  effective_at                        :datetime
#  fulltext_extra                      :string
#  imported_at                         :datetime
#  issue_type                          :integer          default("issue")
#  last_activity_at                    :datetime
#  last_synced_at                      :datetime
#  latitude                            :float
#  legacy_data                         :jsonb
#  likes_count                         :integer          default(0), not null
#  longitude                           :float
#  public                              :boolean          default(FALSE), not null
#  resolution_started_at               :datetime
#  responsible_subject_last_contact_at :datetime
#  title                               :string           not null
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  archived_state_id                   :bigint
#  author_id                           :bigint
#  category_id                         :bigint
#  legacy_id                           :integer
#  municipality_district_id            :bigint
#  municipality_id                     :bigint           not null
#  owner_id                            :bigint
#  resolution_external_id              :integer
#  responsible_subject_id              :bigint
#  state_id                            :bigint
#  subcategory_id                      :bigint
#  subtype_id                          :bigint
#  triage_external_id                  :integer
#
class Praise < Issue
  validates :title, :description, :municipality_id, presence: true

  after_initialize do |praise|
    praise.issue_type = "praise"
  end

  before_create do |praise|
    praise.state = Issues::State.find_by!(key: "waiting")
  end

  after_create do |praise|
    author.subscribe_to(praise)
    SyncIssueToTriageJob.perform_later(praise)
  end
end
