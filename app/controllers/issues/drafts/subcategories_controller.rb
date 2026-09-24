class Issues::Drafts::SubcategoriesController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped

  def show
    @subcategories = Issues::Subcategory.non_legacy.where(category_id: @draft.category_id).all
  end

  def update
    @draft.subcategory = @draft.category.subcategories.find(params[:subcategory_id])
    @draft.subtype = nil # reset
    if @draft.save
      redirect_to issues_draft_subtype_path(@draft, next: params[:next])
    else
      @subcategories = Issues::Subcategory.non_legacy.where(category_id: @draft.category_id).all
      render :show, status: :unprocessable_entity
    end
  end
end
