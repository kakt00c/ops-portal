# == Schema Information
#
# Table name: users
#
#  id                               :bigint           not null, primary key
#  about                            :string
#  active                           :boolean
#  admin_name                       :string
#  anonymous                        :boolean          default(FALSE)
#  banned                           :boolean          default(FALSE)
#  birth                            :date
#  created_from_app                 :boolean          default(FALSE)
#  display_name                     :string
#  email                            :citext           not null
#  email_global_unsubscribe_token   :string           not null
#  email_notifiable                 :boolean          default(TRUE)
#  exp                              :integer
#  fcm_token                        :string
#  firstname                        :string
#  gdpr_accepted                    :boolean
#  gdpr_stats_accepted              :boolean          default(FALSE)
#  imported_at                      :datetime
#  lastname                         :string
#  login                            :string
#  newsletter_accepted              :boolean          default(FALSE), not null
#  onboarded                        :boolean          default(FALSE)
#  organization                     :boolean
#  password_hash                    :string
#  phone                            :string
#  phone_verification_attempted_at  :datetime
#  phone_verification_attempts      :integer          default(0), not null
#  phone_verification_code          :string
#  phone_verification_code_attempts :integer          default(0), not null
#  phone_verified                   :boolean          default(FALSE), not null
#  resident                         :boolean
#  sex                              :integer
#  signature                        :string
#  stats_comments_count             :integer          default(0)
#  stats_comments_percentile        :decimal(5, 4)    default(0.0)
#  stats_issues_count               :integer          default(0)
#  stats_issues_percentile          :decimal(5, 4)    default(0.0)
#  stats_verified_issues_count      :integer          default(0)
#  stats_verified_issues_percentile :decimal(5, 4)    default(0.0)
#  status                           :integer          default("unverified"), not null
#  timestamp                        :datetime
#  type                             :string
#  uuid                             :uuid             not null
#  verification                     :string
#  verified                         :boolean          default(FALSE)
#  created_at                       :datetime         not null
#  updated_at                       :datetime         not null
#  city_id                          :integer
#  external_id                      :integer
#  legacy_id                        :integer
#  municipality_id                  :bigint
#  responsible_subject_id           :bigint
#  street_id                        :bigint
#
class User < ApplicationRecord
  include Rodauth::Rails.model

  ALLOWED_AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/heic image/heif].freeze

  attr_accessor :phone_verification_number

  belongs_to :responsible_subject, class_name: "::ResponsibleSubject", optional: true
  belongs_to :municipality, optional: true
  belongs_to :street, optional: true
  has_many :issues, foreign_key: :author_id
  has_many :issues_drafts, class_name: "Issues::Draft", foreign_key: :author_id
  has_many :issue_likes, foreign_key: :user_id
  has_many :issue_subscriptions, foreign_key: :subscriber_id
  has_many :watched_issues, through: :issue_subscriptions, source: :issue
  has_many :issues_comments, class_name: "Issues::Comment", foreign_key: :user_author_id
  has_many :issues_updates, class_name: "Issues::Update", foreign_key: :author_id
  has_one_attached :avatar do |avatar|
    avatar.variant :tiny, resize_to_fill: [ 36, 36 ]
    avatar.variant :normal, resize_to_fill: [ 65, 65 ], preprocessed: true
    avatar.variant :medium, resize_to_fill: [ 80, 80 ], preprocessed: true
    avatar.variant :big, resize_to_fill: [ 160, 160 ], preprocessed: true
  end

  enum :sex, m: 1, f: 2
  enum :status, { unverified: 1, verified: 2, closed: 3 }

  before_create :set_email_global_unsubscribe_token
  before_save do
    self.firstname = "Používateľ bez mena ##{self.id}" if !self.firstname.present? && !self.lastname.present?
    self.display_name = self.anonymous? ? "Anonym ##{self.id}" : [ self.firstname, self.lastname ].compact.join(" ")
  end

  validates :external_id, uniqueness: true, allow_nil: true
  validates_presence_of :name, unless: -> { legacy_id }
  validates_acceptance_of :terms_of_service, on: :onboarding
  validates :email_global_unsubscribe_token, uniqueness: true, allow_nil: false
  validates_format_of :phone_verification_number, with: /\A\+\d{12}\z/, on: :phone_verification
  validates_numericality_of :phone_verification_attempts, less_than: 5, on: :phone_verification, if: -> { recent_phone_verification? }
  validates_numericality_of :phone_verification_code_attempts, less_than: 10, on: :phone_verification_code
  validates_confirmation_of :phone_verification_code, on: :phone_verification_code
  validates_presence_of :phone_verification_code_confirmation, on: :phone_verification_code
  validate :birth_year_within_range, if: :birth_year, on: [ :onboarding, :update ]
  validate :avatar_content_type_allowed, if: -> { avatar.attached? && avatar.new_record? }

  def name
    [ firstname, lastname ].compact.join(" ")
  end

  def name=(value)
    self.firstname = value
    self.lastname = nil
  end

  def birth_year
    birth&.year
  end

  def birth_year=(value)
    self.birth = value.present? ? Date.new(value.to_i, 1, 1) : nil
  end

  def likes?(thing)
    thing.liked_by?(self)
  end

  def dislikes?(thing)
    thing.disliked_by?(self)
  end

  def subscribed_to?(issue)
    issue_subscriptions.where(issue: issue).exists?
  end

  def subscribe_to(issue)
    issue_subscriptions.create(issue: issue)
  end

  def can_view?(thing)
    thing.viewable_by?(self)
  end

  def can_edit?(thing)
    thing.editable_by?(self)
  end

  def full_access?
    phone_verified?
  end

  def recent_phone_verification?
    return true if phone_verification_attempted_at.nil?

    phone_verification_attempted_at > 1.hour.ago
  end

  def regenerate_phone_verification_code!
    code = 5.times.map { rand(9) }.join
    update!(phone_verification_code: code)
  end

  def create_issue_limit_exceeded?
    issues.where(created_at: 1.month.ago..).count >= ENV.fetch("USER_ISSUE_CREATION_MONTHLY_LIMIT", 10).to_i
  end

  def create_issue_update_limit_exceeded?
    issues_updates.where(created_at: 1.day.ago...).count >= ENV.fetch("USER_ISSUE_UPDATE_DAILY_LIMIT", 5).to_i
  end

  def responsible_subject_for_issue?(issue)
    false
  end

  def current_draft
    draft = issues_drafts.where(created_at: 2.hours.ago..).order(created_at: :desc).first # find recent draft
    return nil if draft.nil? || draft.submitted?

    draft
  end

  def recalculate_computed_fields
    update_columns(
      stats_issues_count: issues.publicly_visible.count,
      stats_comments_count: issues_comments.count,
      stats_verified_issues_count: issues_updates.where(verification_status: :approved).count
    )
  end

  def anonymize!
    avatar.purge if avatar.attached?

    login = "anonymized#{id}_#{SecureRandom.hex(8)}"

    update!(
      email: "#{login}@close.gdpr",
      firstname: "anonymized",
      lastname: nil,
      login: login,
      phone: nil,
      password_hash: RodauthApp.rodauth.allocate.password_hash(SecureRandom.hex(16)),
      about: nil,
      organization: nil,
      signature: nil,
      resident: nil,
      sex: nil,
      birth: nil,
      anonymous: true
    )
  end

  private

  def set_email_global_unsubscribe_token
    loop do
      self.email_global_unsubscribe_token = SecureRandom.urlsafe_base64(32)
      break unless User.exists?(email_global_unsubscribe_token: self.email_global_unsubscribe_token)
    end
  end

  def birth_year_within_range
    unless birth_year.between?(Date.current.year - 120, Date.current.year)
      errors.add(:birth_year, I18n.t("activerecord.errors.models.user.attributes.birth_year.inclusion", min_year: Date.current.year - 120, max_year: Date.current.year))
    end
  end

  def avatar_content_type_allowed
    unless avatar.content_type.in?(ALLOWED_AVATAR_CONTENT_TYPES)
      errors.add(:avatar, :invalid_content_type)
    end
  end
end
