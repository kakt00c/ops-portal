# == Schema Information
#
# Table name: issues_updates
#
#  id                  :bigint           not null, primary key
#  confirmed           :boolean          default(FALSE)
#  email               :string
#  hidden              :boolean          default(FALSE)
#  imported_at         :datetime
#  ip                  :inet
#  last_edited_at      :datetime
#  name                :string
#  published           :boolean
#  resolves_issue      :boolean          default(FALSE), not null
#  text                :string
#  uuid                :uuid
#  verification_status :integer          default("pending"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  activity_id         :bigint           not null
#  author_id           :bigint
#  confirmed_by_id     :bigint
#  external_id         :string
#  legacy_id           :integer
#  triage_external_id  :integer
#
class Issues::Update < ApplicationRecord
  belongs_to :activity, class_name: "Issues::Activity", dependent: :destroy
  belongs_to :author, optional: true, class_name: "User"
  belongs_to :confirmed_by, optional: true, class_name: "Legacy::Agent"
  delegate :issue, to: :activity

  include Issues::ActivityObjectAttachments
  include EditableWithinEditingWindow

  enum :verification_status, { pending: 0, approved: 1, rejected: 2 }, default: :pending

  validates_presence_of :text, if: -> { resolves_issue? && attachments.empty? }
  validates_presence_of :attachments, if: -> { !legacy_id && !resolves_issue? }

  before_create -> { self.uuid = SecureRandom.uuid }

  after_update :notify_subscribers, unless: -> { legacy_id }, if: :saved_change_to_external_id?

  def author_display_name
    return author.display_name if author
    "Neznámy autor"
  end

  def resolves_issue?
    resolves_issue
  end

  def triage_activity_body
    text
  end

  def triage_visible?
    true
  end

  def visible?
    published && !hidden
  end

  def confirmed?
    self.approved? || self.confirmed || self.confirmed_by.present?
  end

  def edited?
    last_edited_at.present?
  end

  def editable_by?(user)
    return false unless author == user
    return false unless within_editing_window?

    true
  end

  def ticket_number
    "U-#{id.to_s.rjust(4, '0')}"
  end

  private

  def notify_subscribers
    Notifications::PublishNewIssueCommentJob.perform_later(self)
  end
end
