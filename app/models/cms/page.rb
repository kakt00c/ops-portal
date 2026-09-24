# == Schema Information
#
# Table name: cms_pages
#
#  id            :bigint           not null, primary key
#  raw           :text             not null
#  slug          :string           not null
#  tags          :string           default([]), is an Array
#  text          :text             not null
#  thumbnail_url :string
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_id   :bigint           not null
#
class Cms::Page < ApplicationRecord
  belongs_to :category, class_name: "Cms::Category", required: true

  validates :title, :slug, :text, presence: true

  def self.thumbnail_from_cooked(html)
    img = Nokogiri::HTML.fragment(html.to_s).css("img").find do |node|
      (node["class"].to_s.split & %w[emoji avatar]).empty?
    end
    normalize_image_url(img["src"]) if img
  end

  def self.normalize_image_url(src)
    return "https:#{src}" if src.start_with?("//")
    return "#{ENV["DISCOURSE_URL"]}#{src}" if src.start_with?("/")

    src
  end

  def self.with_tags(tags)
    if tags.present?
      where("tags @> ARRAY[?]::varchar[]", tags)
    else
      all
    end
  end

  def self.published
    with_tags([ "published" ])
  end

  def self.top
    with_tags([ "top" ])
  end

  def self.find_by_path(root_category, slugs)
    if slugs.count == 2
      category = Cms::Category.find_by(parent_category: root_category, slug: slugs.first)
      return nil if category.nil?

      page = category.find_page_with_slug(slugs.last)
      return nil if page.nil?

      [ category, page ]
    elsif slugs.count == 1
      category = Cms::Category.find_by(parent_category_id: root_category, slug: slugs.first)
      return [ category, nil ] if category

      page = root_category.find_page_with_slug(slugs.first)
      if page
        [ nil, page ]
      else
        nil
      end
    end
  end

  def to_param
    slug
  end
end
