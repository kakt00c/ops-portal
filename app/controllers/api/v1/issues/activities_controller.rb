class Api::V1::Issues::ActivitiesController < ApiController
  before_action :authenticate_client
  before_action :set_issue
  before_action :set_activity, only: [ :show ]

  def show
    @activity = @article
    head :not_found unless @activity
  end

  def create
    unless @client.responsible_subject.external_id.present?
      responsible_subject = @client.responsible_subject
      responsible_subject.external_id = @zammad_client.create_responsible_subject!(responsible_subject)
      responsible_subject.save!
    end

    @activity_id = @zammad_client.create_article_from_api!(@client.responsible_subject.external_id, params.require(:issue_id), activity_params)
  end

  private

  def activity_params
    params.require(:activity).permit(:content_type, :body, attachments: [ :filename, :content_type, :data64 ])
  end

  def set_issue
    return head :not_found unless @client.responsible_subject

    @ticket = @zammad_client.get_ticket(params.require :issue_id)

    return head :not_found unless @ticket
    head :not_found unless @client.responsible_subject.in?([ @ticket[:responsible_subject], @ticket[:previous_responsible_subject] ])
  end

  def set_activity
    @article = @zammad_client.get_article(params.require(:issue_id), params.require(:id), responsible_subject: @client.responsible_subject)

    head :not_found unless @article
  end
end
