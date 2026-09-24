class Cms::PagesController < ApplicationController
  # /:category_slug
  # /:page_slug
  # /:category_slug/:page_slug
  def index
    slugs = params[:path].split("/")

    root_category = Cms::Category.find(ENV["CMS_ROOT_CATEGORY_ID"])
    result = Cms::Page.find_by_path(root_category, slugs)

    return raise_not_found unless result

    @category, @page = result

    return render :show if @page

    pages = @category.pages.published
                    .order(created_at: :desc)

    @top_pages = pages.top.limit(2)

    @hero_pages = pages.excluding(@top_pages)
                       .limit(3)

    base_pages = pages.excluding(@top_pages, @hero_pages)

    current_page = params.fetch(:page, 1).to_i
    total_count = base_pages.count

    records = if current_page == 1
        base_pages.limit(4)
    else
        base_pages.offset(4 + (current_page - 2) * 8)
                  .limit(8)
    end

    @pages = Kaminari::PaginatableArray.new(
      records,
      limit: 8,
      offset: (current_page - 1) * 8,
      total_count: total_count.zero? ? 0 : total_count + 4
    )
  end

  private

  def raise_not_found
    raise ActionController::RoutingError, "Not Found"
  end
end
