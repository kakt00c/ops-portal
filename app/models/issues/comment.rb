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
class Issues::Comment < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :user_author, class_name: "User", optional: true
  belongs_to :agent_author, class_name: "Legacy::Agent", foreign_key: "agent_author_id", optional: true
  belongs_to :responsible_subject_author, class_name: "ResponsibleSubject", optional: true
  delegate :issue, to: :activity

  include Issues::ActivityObjectAttachments

  before_create -> { self.uuid = SecureRandom.uuid }

  def legacy_id
    legacy_comment_id || legacy_communication_id
  end

  def triage_activity_body
    return "Zmazaný komentár: #{text}" if hidden

    text
  end

  def in_triage_as_internal?
    false
  end

  def editable_by?(user)
    false
  end

  def author_display_name
    return author.display_name if author
    author_name
  end

  def duplicate?
    false
  end

  def responsible_subject?
    false
  end

  def agent?
    false
  end

  def edited?
    last_edited_at.present?
  end

  private

  def notify_subscribers
    Notifications::PublishNewIssueCommentJob.perform_later(self)
  end
end
