class Issues::Drafts::CategoriesController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped

  def show
    @categories = ::Issues::Category.non_legacy.includes(:subcategories).all
  end

  def update
    @draft.category = ::Issues::Category.find(params[:category_id])
    @draft.subcategory = @draft.subtype = nil # reset
    if @draft.save
      redirect_to issues_draft_subcategory_path(@draft, next: params[:next])
    else
      render :show, status: :unprocessable_entity
    end
  end
end
