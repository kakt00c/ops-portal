# == Schema Information
#
# Table name: issues_comments
#
#  id                            :bigint           not null, primary key
#  author_email                  :string
#  author_name                   :string
#  hidden                        :boolean          default(FALSE)
#  imported_at                   :datetime
#  ip                            :inet
#  last_edited_at                :datetime
#  legacy_data                   :jsonb
#  text                          :string
#  type                          :string
#  uuid                          :uuid
#  verification                  :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  activity_id                   :bigint           not null
#  agent_author_id               :bigint
#  legacy_comment_id             :integer
#  legacy_communication_id       :integer
#  responsible_subject_author_id :bigint
#  triage_external_id            :integer
#  user_author_id                :bigint
#
class Issues::AgentComment < Issues::Comment
  validates :user_author_id, absence: true
  validates :responsible_subject_author_id, absence: true

  after_create_commit :notify_subscribers, unless: -> { legacy_id }

  def author_display_name
    "Odkaz pre starostu"
  end

  def author
    agent_author
  end

  def triage_activity_body
    [ TriageZammadEnvironment::OPS_PORTAL_ARTICLE_TAG, super ].join(" ")
  end

  def visible?
    !hidden
  end

  def triage_visible?
    visible?
  end

  def agent?
    true
  end
end
