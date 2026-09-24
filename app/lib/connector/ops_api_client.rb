module Connector
  class OpsApiClient
    def initialize(tenant, url: ENV.fetch("CONNECTOR__OPS_API_URL", "http://localhost:3000/"), provider: Faraday)
      @subject = tenant.ops_api_subject_identifier
      @private_key = OpenSSL::PKey::EC.new(tenant.ops_api_token_private_key)
      @url = url
      @provider = provider
    end

    def get_issue(issue_id, include_customer_activities: false, exclude_responsible_subject_articles: false, expand: true)
      response = @provider.get(URI.join(@url, "api/v1/issues/#{issue_id}"), { token: jwt_token, include_customer_activities: include_customer_activities, exclude_responsible_subject_articles: exclude_responsible_subject_articles, expand: expand })

      raise "Issue not found" if response.status == 404
      raise "Unexpected response status: #{response.status}" unless response.status == 200

      JSON.parse response.body
    end

    def update_issue(issue_id, issue_data)
      response = @provider.put(URI.join(@url, "api/v1/issues/#{issue_id}"), { issue: issue_data, token: jwt_token })

      raise "Issue not found" if response.status == 404
      raise "Unexpected response status: #{response.status}" unless response.status == 200
    end

    def get_activity(issue_id, activity_id)
      response = @provider.get(URI.join(@url, "api/v1/issues/#{issue_id}/activities/#{activity_id}"), { token: jwt_token })

      raise "Activity not found" if response.status == 404
      raise "Unexpected response status: #{response.status}" unless response.status == 200

      JSON.parse response.body
    end

    def create_activity!(issue_id, activity)
      response = @provider.post(
        URI.join(@url, "api/v1/issues/#{issue_id}/activities"),
        { activity: activity }.to_json,
        { "Content-Type" => "application/json", "Authorization" => "Bearer #{jwt_token}" }
      )

      raise "Issue not found" if response.status == 404
      raise "Unexpected response status: #{response.status}" unless response.status == 200

      JSON.parse(response.body)["activity_id"]
    end

    private

    def jwt_token
      JWT.encode({
          sub: @subject,
          exp: 5.minutes.from_now.to_i,
          jti: SecureRandom.uuid
        },
        @private_key,
        "ES256"
      )
    end
  end
end
