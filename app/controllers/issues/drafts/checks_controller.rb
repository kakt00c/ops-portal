class Issues::Drafts::ChecksController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped

  def show
    @draft.valid?(:checks_step)
  end

  def confirm
    if @draft.confirmable?
      @draft.confirm

      redirect_to thanks_issues_drafts_path
    end
  end

  def create
    Issues::Draft::GenerateChecksJob.perform_now(@draft) if @draft.checks.nil?
    Issues::Draft::FetchAddressDetailsJob.perform_now(@draft) if @draft.address_data.nil?
    if @draft.valid?(:checks_step)
      @draft.confirm
      redirect_to thanks_issues_drafts_path
    else
      redirect_to action: :show
    end
  end
end
