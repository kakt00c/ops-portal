def generate_cms_page(title:, slug:, category_id:, text: nil, tags: [ "published" ], days_ago: 7)
  Cms::Page.find_or_create_by!(slug: slug, category_id: category_id) do |page|
    page.title = title
    page.text = text || 5.times.map { Faker::Lorem.paragraph_by_chars }.map { |par| "<p>#{par}</p>" }.join("\n")
    page.raw = ""
    page.tags = tags
    page.created_at = DateTime.now - days_ago.days
    page.updated_at = DateTime.now - days_ago.days
  end
end

cms_root = Cms::Category.find_or_create_by!(
  id: ENV["CMS_ROOT_CATEGORY_ID"],
  slug: "cms",
  ) do |category|
  category.name = "CMS"
end

cms_novinky = Cms::Category.find_or_create_by!(
  slug: "aktuality",
  parent_category_id: cms_root.id,
  ) do |category|
  category.name = "Aktuality"
end

# Static pages
[
  "O nás",
  "Pravidla",
  "Kontakt",
  "Pridajte sa",
  "Podporte nás",
  "Zásady ochrany osobných údajov",
  "Partneri"
].each { |title| generate_cms_page(category_id: cms_root.id, title: title, slug: title.parameterize) }

# Named announcements
[
  { slug: "new-portal", title: "New Portal!", days_ago: 7,
    text: "<p><strong>Lorem Ipsum</strong> is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.</p>" * 4 },
  { slug: "community-guidelines", title: "Updated Community Guidelines", days_ago: 6, tags: [],
    text: "<p>We've updated our community guidelines to ensure a safer environment for all.</p>" * 4 },
  { slug: "dark-mode", title: "Dark Mode is Here!", days_ago: 5,
    text: "<p><strong>Great news!</strong> Dark Mode has been added to improve your experience and reduce eye strain. You can enable it in your settings and enjoy a sleeker, more comfortable interface.</p>" * 4 },
  { slug: "holiday-hours", title: "Holiday Hours Notice", days_ago: 4,
    text: "<p>Check out our adjusted operating hours for the upcoming holiday season.</p>" * 4 },
  { slug: "system-maintenance", title: "System Maintenance Scheduled", days_ago: 3, tags: [],
    text: "<p><strong>Attention!</strong> Our team will conduct routine maintenance to enhance security and performance. During this time, some services may be temporarily unavailable. We apologize for any inconvenience and appreciate your patience.</p>" * 4 },
  { slug: "mobile-app-release", title: "Our Mobile App is Live!", days_ago: 2,
    text: "<p><strong>Great news!</strong> Our brand-new mobile app is now available for download on iOS and Android. Enjoy a seamless experience with enhanced features, push notifications, and improved performance. Get it today and stay connected on the go!</p>" * 4 },
  { slug: "dashboard-upgrade", title: "New and Improved User Dashboard!", days_ago: 1, tags: [],
    text: "<p><strong>Exciting updates!</strong> Your user dashboard just got a major upgrade. We've improved navigation, added new analytics tools, and enhanced performance to make your experience smoother and more efficient. Log in now to explore the new design!</p>" * 4 }
].each { |params| generate_cms_page(category_id: cms_novinky.id, **params) }

# Random announcements
10.times do |n|
  title = Faker::Lorem.sentence

  generate_cms_page(
    category_id: cms_novinky.id,
    slug: title.parameterize,
    title: title,
    days_ago: 40 - n,
  )
end
