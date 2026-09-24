SitemapGenerator::Sitemap.default_host = "https://novy.odkazprestarostu.sk/"
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps/"

# Ping search engines when sitemap is generated
# Google deprecated their ping endpoint - use Search Console instead
# Bing still supports pinging
SitemapGenerator::Sitemap.search_engines = {
  bing: "http://www.bing.com/webmasterportal/ping.aspx?siteMap=%s"
}

SitemapGenerator::Sitemap.create do
  add root_path, changefreq: "daily", priority: 1.0

  add "/aktuality", changefreq: "weekly", priority: 0.8

  Issue.searchable.find_each do |issue|
    add issue_path(issue),
        lastmod: issue.updated_at,
        changefreq: "weekly",
        priority: 0.8
  end

  root_category_id = ENV["CMS_ROOT_CATEGORY_ID"].to_i
  Cms::Page.published.includes(:category).find_each do |page|
    if page.category_id == root_category_id || page.category.nil?
      path = page.slug
    else
      path = "#{page.category.slug}/#{page.slug}"
    end

    add path, lastmod: page.updated_at, changefreq: "weekly", priority: 0.7
  end

  Municipality.active.where(active_on_old_portal: false).find_each do |municipality|
    add issues_path(obec: municipality.name),
        changefreq: "daily",
        priority: 0.6
  end
end
