class Cms::ImportPageJob < ApplicationJob
  def perform(topic_id, discourse_client: DiscourseApiClient.new)
    topic_result = discourse_client.load_topic(topic_id)

    page = Cms::Page.find_by(id: topic_result["id"])
    if topic_result["deleted_at"]
      page.destroy! if page

      return
    end

    # category exists, everything is ok
    category = Cms::Category.find_by(id: topic_result["category_id"])
    if category
      post_id = topic_result.dig("post_stream", "posts", 0, "id")
      post_result = discourse_client.load_post(post_id)

      upsert_page(topic_result, post_result, category)
    else
      page.destroy! if page # if the page was moved to the not existing category, we consider it as deleted
    end
  end

  private

  def upsert_page(topic_raw, post_raw, category)
    Cms::Page.find_or_initialize_by(id: topic_raw["id"]).tap do |page|
      page.assign_attributes(
        title: topic_raw["title"],
        slug: topic_raw["slug"],
        tags: topic_raw["tags"].map { |tag| tag["name"] },
        text: post_raw["cooked"],
        thumbnail_url: topic_raw["image_url"].presence || Cms::Page.thumbnail_from_cooked(post_raw["cooked"]),
        raw: post_raw["raw"],
        category: category,
        created_at: topic_raw["created_at"],
      )
      page.save!
    end
  end
end
