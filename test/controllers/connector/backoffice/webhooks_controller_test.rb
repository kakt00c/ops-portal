require "test_helper"

class Connector::Backoffice::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = connector_tenants(:default)
  end

  def post_signed(payload, secret: @tenant.backoffice_webhook_secret, signature: nil)
    body = payload.to_json
    signature ||= OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret, body)
    post connector_backoffice_webhook_url, params: body, headers: { "Content-Type" => "application/json", "X-Hub-Signature" => "sha1=#{signature}" }
  end

  def payload(type, **data)
    { type: type, data: { tenant_id: @tenant.id, **data } }
  end

  # Authentication

  test "requests without signature are unauthorized" do
    assert_no_enqueued_jobs do
      post connector_backoffice_webhook_url, params: payload("ticket.updated", ticket_id: "42").to_json, headers: { "Content-Type" => "application/json" }
    end
    assert_response :unauthorized
  end

  test "requests with wrong signature are forbidden" do
    assert_no_enqueued_jobs do
      post_signed payload("ticket.updated", ticket_id: "42"), secret: "wrong"
    end
    assert_response :forbidden
  end

  test "requests signed with another tenant's secret are forbidden" do
    assert_no_enqueued_jobs do
      post_signed payload("ticket.updated", ticket_id: "42"), secret: connector_tenants(:other).backoffice_webhook_secret
    end
    assert_response :forbidden
  end

  test "requests for an unknown tenant are not found" do
    assert_no_enqueued_jobs do
      post_signed({ type: "ticket.updated", data: { tenant_id: 0, ticket_id: "42" } })
    end
    assert_response :not_found
  end

  test "requests for an inactive tenant are not found" do
    @tenant.inactive!

    assert_no_enqueued_jobs do
      post_signed payload("ticket.updated", ticket_id: "42")
    end
    assert_response :not_found
  end

  test "requests without tenant are bad requests" do
    post_signed({ type: "ticket.updated", data: { ticket_id: "42" } })

    assert_response :bad_request
  end

  # Events

  test "article.created processes the new backoffice article" do
    assert_enqueued_with(job: Connector::ProcessNewBackofficeArticleJob, args: [ @tenant, "42", "7" ]) do
      post_signed payload("article.created", ticket_id: "42", article_id: "7")
    end
    assert_response :no_content
  end

  test "article.created without article is a bad request" do
    assert_no_enqueued_jobs do
      post_signed payload("article.created", ticket_id: "42")
    end
    assert_response :bad_request
  end

  test "ticket.updated syncs the issue to triage and updates subtasks" do
    post_signed payload("ticket.updated", ticket_id: "42")

    assert_response :no_content
    assert_enqueued_with(job: Connector::UpdateTriageIssueFromBackofficeJob, args: [ @tenant, "42" ])
    assert_enqueued_with(job: Connector::UpdateSubtaskFromParentTicketJob, args: [ @tenant, { ticket_id: "42" } ])
  end

  test "unknown event is unprocessable" do
    assert_no_enqueued_jobs do
      post_signed payload("ticket.created", ticket_id: "42")
    end
    assert_response :unprocessable_entity
  end
end
