namespace :cms do
  desc "Schedules initial import from CMS categories and pages"
  task import: :environment do
    Cms::InitialImportJob.perform_later
  end

  desc "Backfills thumbnail_url from cooked content for pages missing one"
  task backfill_thumbnails: :environment do
    Cms::Page.where("thumbnail_url IS NULL OR thumbnail_url = ''").find_each do |page|
      thumbnail = Cms::Page.thumbnail_from_cooked(page.text)
      page.update_column(:thumbnail_url, thumbnail) if thumbnail
    end
  end
end
