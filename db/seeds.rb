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

  webhook_url = "http://localhost:3000/connector/webhook"
  default_connector_zammad_api_token = "CsnpmnPAlMZCmbaClOoWE7QlFPgCsElVLsfgkJMZQfs"
  default_connector_zammad_webhook_secret = "6fvpqr777ryN9FTqkRH2xYGWFXU1W862R6NUyhQOErN"

  [
    {
      name: "MÚ Staré Mesto",
      pro: true,
      url: webhook_url,
      connector_zammad_url: "http://localhost:8081/",
      connector_zammad_api_token: default_connector_zammad_api_token,
      connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
    },
    {
      name: "Hlavné mesto SR Bratislava",
      pro: true,
      url: webhook_url,
      connector_zammad_url: "http://localhost:8082/",
      connector_zammad_api_token: default_connector_zammad_api_token,
      connector_zammad_webhook_secret: default_connector_zammad_webhook_secret
    },
    {
      name: "MÚ Nové Mesto",
      pro: false
    }
  ].each do |data|
    responsible_subject_type = ResponsibleSubjects::Type.find_or_create_by!(name: "Mestský úrad")
    responsible_subject = ResponsibleSubject.find_or_create_by!(name: data[:name], responsible_subjects_type_id: responsible_subject_type.id)
    responsible_subject.update_columns(
      subject_name: data[:name],
      active: true,
      pro: data[:pro]
    )

    next unless data[:pro]

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
end

[
  {
    name: "Zaslaný zodpovednému",
    key: "sent_to_responsible"
  },
  {
    name: "Odstúpený",
    key: "referred"
  },
  {
    name: "Čakajúci",
    key: "waiting"
  },
  {
    name: "Vyriešený",
    key: "resolved"
  },
  {
    name: "Vyriešený (skrytý)",
    key: "resolved_private"
  },
  {
    name: "Neriešený",
    key: "unresolved"
  },
  {
    name: "V riešení",
    key: "in_progress"
  },
  {
    name: "Zamietnutý",
    key: "rejected"
  },
  {
    name: "Uzavretý",
    key: "closed"
  },
  {
    name: "Označený za vyriešený",
    key: "marked_as_resolved"
  },
  {
    name: "Duplicitný",
    key: "duplicate"
  },
  {
    name: "Čaká na autora",
    key: "waiting_for_author"
  }
].each do |state_data|
  Issues::State.find_or_create_by!(key: state_data[:key]).tap do |issues_state|
    issues_state.update(name: state_data[:name])
  end
end
