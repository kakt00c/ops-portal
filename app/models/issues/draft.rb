# == Schema Information
#
# Table name: issues_drafts
#
#  id                      :bigint           not null, primary key
#  address_city            :string
#  address_country         :string
#  address_country_code    :string
#  address_data            :jsonb
#  address_district        :string
#  address_house_number    :string
#  address_municipality    :string
#  address_postcode        :string
#  address_region          :string
#  address_street          :string
#  address_suburb          :string
#  anonymous               :boolean
#  checks                  :jsonb
#  description             :string
#  duplicates_shown        :boolean          default(FALSE), not null
#  issue_type              :string           default("issue"), not null
#  latitude                :float
#  latlon_from_exif        :boolean          default(FALSE)
#  longitude               :float
#  picked_suggestion_index :integer
#  submitted               :boolean          default(FALSE), not null
#  suggestions             :jsonb
#  title                   :string
#  zoom                    :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  author_id               :bigint           not null
#  category_id             :bigint
#  issue_id                :bigint
#  subcategory_id          :bigint
#  subtype_id              :bigint
#
class Issues::Draft < ApplicationRecord
  has_many_attached :photos do |photo|
    photo.variant :llm, resize_to_limit: [ 800, 600 ], preprocessed: true
    photo.variant :thumb, resize_to_limit: [ 320, 240 ], preprocessed: true
    photo.variant :square, resize_to_fill: [ 320, 320 ], preprocessed: true
    photo.variant :normal, resize_to_fill: [ 800, 800 ]
    photo.variant :small, resize_to_fill: [ 360, 360 ]
  end

  belongs_to :issue, optional: true
  belongs_to :category, class_name: "Issues::Category", optional: true
  belongs_to :subcategory, class_name: "Issues::Subcategory", optional: true
  belongs_to :subtype, class_name: "Issues::Subtype", optional: true
  belongs_to :author, class_name: "User", optional: false

  validates_presence_of :photos, on: :photos_step
  validates_presence_of :title, :description, on: :details_step
  validates_length_of :title, minimum: 10, maximum: 80, allow_blank: true, on: :details_step
  validates_length_of :description, minimum: 25, maximum: 1800, allow_blank: true, on: :details_step

  validate :latlon_present, on: :geo_step
  validates_numericality_of :zoom, greater_than: 14, allow_nil: true, on: :geo_step
  validate :photos_allowed_content_type, on: :photos_step

  validate :no_duplicates_nearby, on: :checks_step, unless: :duplicates_shown?
  validate :municipality_supported, on: [ :suggestions_step, :details_step, :checks_step ]
  validate :checks_passed, on: :checks_step

  before_save :reset_address_details, if: -> { will_save_change_to_latitude? || will_save_change_to_longitude? }

  def confirm
    municipality, municipality_district = Municipality.find_by_coordinates(latitude, longitude, street: address_street)

    Issue.transaction do
      issue = Issue.new(
        issue_type: issue_type,
        title: title,
        description: description,
        author: author,
        anonymous: anonymous,
        latitude: latitude,
        longitude: longitude,
        address_country: address_country,
        address_country_code: address_country_code,
        address_region: address_region,
        address_suburb: address_suburb,
        address_district: address_district,
        address_city: address_city,
        address_municipality: address_municipality,
        address_street: address_street,
        address_house_number: address_house_number,
        address_postcode: address_postcode,
        category: category,
        subcategory: subcategory,
        subtype: subtype,
        state: Issues::State.find_by!(key: "waiting"),
        municipality: municipality,
        municipality_district: municipality_district,
      )

      photos.each do |photo|
        issue.photos.attach(photo.blob)
      end

      issue.save!
      issue.author.subscribe_to(issue)

      self.update!(submitted: true, issue: issue)

      SyncIssueToTriageJob.perform_later(issue)
    end
  end

  def needs_editing?
    checks.any? { |check| check["action"] == "back" }
  end

  def geo
    [ latitude, longitude ] if latitude.present? && longitude.present?
  end

  def load_geo_from_exif(photo)
    begin
      d = Exif::Data.new(photo.blob.download)
    rescue Exif::NotReadable
      return
    end

    gps = d[:gps]
    if gps && valid_gps?(gps[:gps_latitude]) && valid_gps?(gps[:gps_longitude])
      self.latitude = gps_to_float(gps[:gps_latitude])
      self.longitude = gps_to_float(gps[:gps_longitude])
      self.latlon_from_exif = true
    end
  end

  def update_with_context(attributes, context)
    # TODO move to AR monkey-patch
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(context: context)
    end
  end

  def pick_suggestion(suggestions_params)
    assign_attributes(suggestions_params)
    if picked_suggestion_index == -1
      self.title = self.description = nil
    else
      self.title, self.description, category_suggestion, subcategory_suggestion, subtype_suggestion = suggestions[picked_suggestion_index]&.values_at("title", "description", "category", "subcategory", "subtype")
      self.category = Issues::Category.find_by(name: category_suggestion)
      self.subcategory = self.category&.subcategories&.find_by(name: subcategory_suggestion)
      self.subtype = self.subcategory&.subtypes&.find_by(name: subtype_suggestion)
    end
    self.checks = nil # reset checks
    save(context: :suggestions_step)
  end

  def confirmable?
    checks.all? { |check| check["action"] == "confirm" }
  end

  def municipality_errors?
    errors.added?(:base, :municipality_unsupported) ||
      errors.added?(:base, :municipality_district_unsupported) ||
      errors.added?(:base, :municipality_supported_on_old_portal)
  end

  private

  def photos_allowed_content_type
    errors.add(:photos, :invalid_content) if photos.any? { |file| !file.content_type.in?(UploadsController::ALLOWED_CONTENT_TYPES) }
  end

  def latlon_present
    errors.add(:base, :latlon_missing) if latitude.blank? || longitude.blank?
  end

  def no_duplicates_nearby
    nearby_issues = Issue
      .publicly_visible
      .within_distance_from_point(latitude, longitude, 500)
      .where(category: category, subcategory: subcategory)
    nearby_issues = nearby_issues.where(subtype: subtype) if subtype.present?

    errors.add(:base, :duplicates_nearby) if nearby_issues.any?
  end

  def checks_passed
    errors.add(:checks, :invalid) if checks.any?
  end

  def municipality_supported
    return if latitude.blank? || longitude.blank?

    active_municipality, municipality_district = Municipality.find_by_coordinates(latitude, longitude, street: address_street)
    errors.add(:base, :municipality_supported_on_old_portal) if active_municipality && active_municipality.active_on_old_portal?
    errors.add(:base, :municipality_unsupported) if active_municipality.nil? && municipality_district.nil?
    errors.add(:base, :municipality_district_unsupported) if active_municipality.nil? && municipality_district
  end

  def reset_address_details
    self.address_data = nil
    self.address_municipality = nil
    self.address_district = nil
    self.address_city = nil
    self.address_street = nil
  end

  def gps_to_float(gps)
    d, m, s = gps
    d.to_f + m / 60 + s / 3600
  end

  def valid_gps?(gps)
    gps.is_a?(Array) && gps.length == 3 && gps.all? { |v| !v.to_f.nan? }
  end
end
