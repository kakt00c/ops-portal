class Issues::Drafts::GeosController < ApplicationController
  before_action :require_full_access_user
  include Issues::DraftScoped

  def show
    @draft.load_geo_from_exif(@draft.photos.first) unless @draft.geo.present?
  end

  def update
    if @draft.update_with_context(geo_params, :geo_step)
      if params[:next] == "summary"
        Issues::Draft::FetchAddressDetailsJob.perform_now(@draft)
        redirect_to issues_draft_summary_path(@draft)
      else
        Issues::Draft::FetchAddressDetailsJob.perform_later(@draft)
        redirect_to issues_draft_suggestions_path(@draft)
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def geo_params
    params.expect(issues_draft: [ :longitude, :latitude, :zoom ])
  end
end
