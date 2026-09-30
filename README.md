# README

## Install on Mac

Install this before running `bundle`:
- `brew install pkg-config`
- `brew install libexif`
- `brew install vips`


## Testing

Run `bin/rails test:all`. See [docs/TESTING.md](docs/TESTING.md) for what to test at which level.

## Connect new Backoffice instance

Tip: Use [CyberChef](https://gchq.github.io/CyberChef/#recipe=Pseudo-Random_Number_Generator(32,'Raw')To_Base62('0-9A-Za-z')) to generate secrets.

Example:

```ruby
new_backoffice_data = {
  name: "Malacky",
  url: "https://novy.odkazprestarostu.sk/connector/webhook",
  connector_zammad_url: "https://malacky.odkazprestarostu.sk/",
  receive_customer_activities: false,
  connector_zammad_api_token: "tokenvalue",
  connector_zammad_webhook_secret: "secretvalue"
}

def connect_backoffice(data)
  responsible_subject = ResponsibleSubject.find_by!(name: data[:name])

  raise "ResponsibleSubject already PRO" if responsible_subject.pro?

  responsible_subject.update_columns(
    subject_name: data[:name],
    active: true,
    pro: true
  )

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
    backoffice_url: data[:connector_zammad_url],
    receive_customer_activities: data[:receive_customer_activities]
  )
end

connect_backoffice new_backoffice_data
```
