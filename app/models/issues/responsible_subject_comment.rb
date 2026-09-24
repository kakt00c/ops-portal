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
class Issues::ResponsibleSubjectComment < Issues::Comment
  validates :agent_author_id, absence: true
  validates :user_author_id, absence: true
  validates :text, presence: true, if: -> { attachments.empty? }, unless: -> { legacy_id }

  include EditableWithinEditingWindow

  after_create_commit :notify_subscribers, unless: -> { legacy_id }

  def author
    responsible_subject_author
  end

  def author_display_name
    responsible_subject_author&.subject_name || "Odpoveď zodpovedného subjektu"
  end

  def backoffice_author
    ::ResponsibleSubjects::User.find_by(legacy_id: legacy_data&.fetch("user_id"))
  end

  def triage_activity_body
    super
  end

  def backoffice_activity_body
    text
  end

  def internal?
    false
  end

  def visible?
    !hidden
  end

  def triage_visible?
    visible?
  end

  def responsible_subject?
    true
  end

  def editable_by?(user)
    return false unless responsible_subject_author == user.responsible_subject
    return false unless within_editing_window?

    true
  end
end
