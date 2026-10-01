require_relative "seeds/categories"
require_relative "seeds/issue_states"

# start after legacy data
last_id = ActiveRecord::Base.connection.select_value("SELECT last_value FROM issues_id_seq")
if last_id < 300000
  ActiveRecord::Base.connection.execute "ALTER SEQUENCE issues_id_seq RESTART WITH 300000;"
end

if Rails.env.development?
  require_relative "seeds/ai_prompts"
  require_relative "seeds/cms_pages"
  require_relative "seeds/municipalities"
  require_relative "seeds/responsible_subjects"
  require_relative "seeds/responsible_subjects_categories"

  webhook_url = "http://localhost:3000/connector/webhook"
  default_connector_zammad_api_token = "CsnpmnPAlMZCmbaClOoWE7QlFPgCsElVLsfgkJMZQfs"
  default_connector_zammad_webhook_secret = "6fvpqr777ryN9FTqkRH2xYGWFXU1W862R6NUyhQOErN"

  [
    {
      name: "MÚ Staré Mesto",
      url: webhook_url,
      connector_zammad_url: "http://localhost:8081/",
      connector_zammad_api_token: default_connector_zammad_api_token,
      connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
    },
    {
      name: "Hlavné mesto SR Bratislava",
      url: webhook_url,
      connector_zammad_url: "http://localhost:8082/",
      connector_zammad_api_token: default_connector_zammad_api_token,
      connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
    }
  ].each do |data|
    responsible_subject = ResponsibleSubject.find_by!(subject_name: data[:name])

    client = Client.find_or_create_by!(name: data[:name])
    tenant = Connector::Tenant.find_or_create_by!(name: data[:name])

    api_key = OpenSSL::PKey::EC.generate("prime256v1")
    webhook_key = OpenSSL::PKey::EC.generate("prime256v1")

    client.update_columns(
      api_token_public_key: api_key.public_to_pem,
      webhook_private_key: webhook_key.to_pem,
      url: data[:url],
      responsible_subject_id: responsible_subject.id
    )

    tenant.update_columns(
      backoffice_api_token: data[:connector_zammad_api_token],
      backoffice_webhook_secret: data[:connector_zammad_webhook_secret],
      ops_api_token_private_key: api_key.to_pem,
      ops_webhook_public_key: webhook_key.public_to_pem,
      ops_api_subject_identifier: client.id,
      backoffice_url: data[:connector_zammad_url]
    )
  end

  require_relative "seeds/users"
  require_relative "seeds/issues"
end
