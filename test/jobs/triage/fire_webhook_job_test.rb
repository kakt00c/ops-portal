require "test_helper"

class Triage::FireWebhookJobTest < ActiveJob::TestCase
  setup do
    @client = clients(:pro_backoffice)
    @payload = { type: "issue.created", timestamp: 1_700_000_000, data: { subject_id: @client.id, issue_id: 42 } }
  end

  test "posts the signed payload to the client's url" do
    stub_request(:post, @client.url).to_return(status: 204)

    Triage::FireWebhookJob.perform_now(@client, "hook-1", @payload)

    assert_requested(:post, @client.url) do |request|
      assert_equal @payload.to_json, request.body
      assert_equal "hook-1", request.headers["Webhook-Id"]
      assert_equal "application/json", request.headers["Content-Type"]

      timestamp = request.headers["Webhook-Timestamp"]
      version, signature = request.headers["Webhook-Signature"].split(",", 2)
      assert_equal "v1a", version

      public_key = OpenSSL::PKey::EC.new(@client.webhook_private_key)
      digest = OpenSSL::Digest.digest("SHA256", "hook-1.#{timestamp}.#{request.body}")
      assert public_key.verify_raw("SHA256", Base64.strict_decode64(signature), digest), "signature must verify with the client's public key"
    end
  end

  test "failed delivery is retried" do
    stub_request(:post, @client.url).to_return(status: 500, body: "boom")

    assert_enqueued_with(job: Triage::FireWebhookJob) do
      Triage::FireWebhookJob.perform_now(@client, "hook-1", @payload)
    end
  end
end
