class Triage::FireWebhookJob < ApplicationJob
  retry_on StandardError, wait: :polynomially_longer, attempts: 10

  def perform(client, webhook_id, payload, provider: Faraday)
    private_key = OpenSSL::PKey::EC.new client.webhook_private_key
    attempt_timestamp = Time.now.to_i

    hash = OpenSSL::Digest.digest "SHA256", "#{webhook_id}.#{attempt_timestamp}.#{payload.to_json}"
    signature = private_key.sign_raw "SHA256", hash
    headers = {
      "webhook-id" => webhook_id,
      "webhook-timestamp" => attempt_timestamp.to_s,
      "webhook-signature" => "v1a,#{Base64.strict_encode64 signature}",
      "Content-Type" => "application/json"
    }

    response = provider.post(client.url, payload.to_json, headers)
    raise "Unexpected response status: #{response.status} with body: #{response.body}" unless response.status&.between?(200, 299)
  end
end
