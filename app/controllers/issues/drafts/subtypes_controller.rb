class Issues::Drafts::SubtypesController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped

  def show
    @subtypes = Issues::Subtype.non_legacy.where(subcategory_id: @draft.subcategory_id).all
    redirect_to next_step_path if @subtypes.empty?
  end

  def update
    @draft.subtype = @draft.subcategory.subtypes.find(params[:subtype_id])
    if @draft.save
      redirect_to next_step_path
    else
      @subtypes = Issues::Subtype.non_legacy.where(subcategory_id: @draft.subcategory_id).all
      render :show, status: :unprocessable_entity
    end
  end

  private

  def next_step_path
    params[:next] == "summary" ? issues_draft_summary_path(@draft) : issues_draft_details_path(@draft)
  end
end
