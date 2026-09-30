class Connector::Backoffice::WebhooksController < ActionController::API
  before_action :set_tenant
  before_action :authenticate

  def webhook
    event_type = webhook_params.require :type

    case event_type
    when "article.created"
      Connector::ProcessNewBackofficeArticleJob.perform_later(@tenant, data.require(:ticket_id), data.require(:article_id))
    when "ticket.updated"
      Connector::UpdateTriageIssueFromBackofficeJob.perform_later(@tenant, data.require(:ticket_id))
      Connector::UpdateSubtaskFromParentTicketJob.perform_later(@tenant, ticket_id: data.require(:ticket_id))
    else
      render json: "Unrecognized webhook event: #{event_type}", status: :unprocessable_entity
    end
  end

  private

  def webhook_params
    params.permit(:type, :timestamp, :data)
  end

  def data
    params.require(:data).permit(:ticket_id, :article_id, :tenant_id)
  end

  def set_tenant
    @tenant = Connector::Tenant.active.find(data.require(:tenant_id))
  end

  def authenticate
    sig_header = request.headers["X-Hub-Signature"]&.gsub("sha1=", "")
    render status: :unauthorized, json: nil and return unless sig_header.present?

    secret = @tenant.backoffice_webhook_secret
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret, request.body.read)
    render status: :forbidden, json: nil unless ActiveSupport::SecurityUtils.secure_compare(signature, sig_header)
  end
end
