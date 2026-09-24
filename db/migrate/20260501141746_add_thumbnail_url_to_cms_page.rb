class AddThumbnailUrlToCmsPage < ActiveRecord::Migration[8.1]
  def change
    add_column :cms_pages, :thumbnail_url, :string
  end
end
