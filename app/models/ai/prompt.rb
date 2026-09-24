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
module Ai
  class Prompt < Cms::Page
    class PromptNotFoundException < StandardError
    end

    def self.get(prompt_name)
      prompt = joins(:category)
        .where(cms_categories: { id: ENV.fetch("CMS_AI_CATEGORY_ID") })
        .with_tags("prompt:#{prompt_name}")
        .first

      raise PromptNotFoundException, prompt_name unless prompt

      replace_placeholders(prompt.raw)
    end

    private

    def self.replace_placeholders(content)
      content.gsub("{{ CATEGORIES_TABLE }}") { generate_categories_table }
    end

    def self.generate_categories_table
      table_rows = []

      Issues::Category.non_legacy.order(:name).each do |category|
        category.subcategories.non_legacy.order(:name).each do |subcategory|
          if subcategory.subtypes.non_legacy.any?
            subcategory.subtypes.non_legacy.order(:name).each do |subtype|
              table_rows << "| #{category.name} | #{subcategory.name} | #{subtype.name} |"
            end
          else
            table_rows << "| #{category.name} | #{subcategory.name} | - |"
          end
        end
      end

      "| category | subcategory | subtype |\n| -------- | ----------- | ------- |\n" + table_rows.join("\n")
    end
  end
end
