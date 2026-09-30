require "test_helper"

class Triage::WebhooksControllerTest < ActionDispatch::IntegrationTest
  def post_signed(path, payload, secret: ENV.fetch("TRIAGE_ZAMMAD_WEBHOOK_SECRET"))
    body = payload.to_json
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha1"), secret, body)
    post path, params: body, headers: { "Content-Type" => "application/json", "X-Hub-Signature" => "sha1=#{signature}" }
  end

  test "requests without signature are unauthorized" do
    post triage_webhooks_portal_url
    assert_response :unauthorized
  end

  test "requests with wrong signature are forbidden" do
    post_signed triage_webhooks_portal_url, { type: "ticket.updated", data: { ticket_id: 1 } }, secret: "wrong"
    assert_response :forbidden
  end

  # portal

  test "portal ticket.updated enqueues ticket sync" do
    assert_enqueued_with(job: Triage::SyncTicketUpdateFromTriageJob, args: [ "42" ]) do
      post_signed triage_webhooks_portal_url, { type: "ticket.updated", data: { ticket_id: "42" } }
    end
    assert_response :no_content
  end

  test "portal article.created enqueues activity creation" do
    assert_enqueued_with(job: Triage::CreateNewPortalActivityFromTriageJob, args: [ "42", "7" ]) do
      post_signed triage_webhooks_portal_url, { type: "article.created", data: { ticket_id: "42", article_id: "7" } }
    end
    assert_response :no_content
  end

  test "portal unknown event is unprocessable" do
    assert_no_enqueued_jobs do
      post_signed triage_webhooks_portal_url, { type: "ticket.created", data: { ticket_id: "42" } }
    end
    assert_response :unprocessable_entity
  end

  # responsible subject

  test "responsible subject ticket.created forwards new issue to backoffice" do
    assert_enqueued_with(job: Triage::SendNewIssueFromTriageToBackofficeJob, args: [ "42" ]) do
      post_signed triage_webhooks_responsible_subject_url, { type: "ticket.created", data: { ticket_id: "42" } }
    end
    assert_response :no_content
  end

  test "responsible subject article.created processes new activity" do
    assert_enqueued_with(job: Triage::ProcessNewActivityFromTriageJob, args: [ "42", "7" ]) do
      post_signed triage_webhooks_responsible_subject_url, { type: "article.created", data: { ticket_id: "42", article_id: "7" } }
    end
    assert_response :no_content
  end

  test "responsible subject ticket.updated forwards issue update to backoffice" do
    assert_enqueued_with(job: Triage::SendNewIssueUpdateFromTriageToBackofficeJob, args: [ "42" ]) do
      post_signed triage_webhooks_responsible_subject_url, { type: "ticket.updated", data: { ticket_id: "42" } }
    end
    assert_response :no_content
  end

  test "responsible subject unknown event is unprocessable" do
    post_signed triage_webhooks_responsible_subject_url, { type: "user.updated", data: { user_id: "1" } }
    assert_response :unprocessable_entity
  end

  # common

  test "common article.updated updates portal activity" do
    assert_enqueued_with(job: Triage::UpdatePortalActivityFromTriageJob, args: [ "42", "7" ]) do
      post_signed triage_webhooks_common_url, { type: "article.updated", data: { ticket_id: "42", article_id: "7" } }
    end
    assert_response :no_content
  end

  test "common user.updated updates portal user" do
    assert_enqueued_with(job: Triage::UpdatePortalUserFromTriageJob, args: [ "9" ]) do
      post_signed triage_webhooks_common_url, { type: "user.updated", data: { user_id: "9" } }
    end
    assert_response :no_content
  end

  test "common unknown event is unprocessable" do
    post_signed triage_webhooks_common_url, { type: "ticket.updated", data: { ticket_id: "42" } }
    assert_response :unprocessable_entity
  end
end
