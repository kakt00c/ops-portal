module ZammadHelper
  # Stubs a Zammad REST call, on the triage instance (TRIAGE_ZAMMAD_URL) unless `url` is given.
  #
  #   stub_zammad(:get, "tickets/42", fixture: "zammad/ticket_resolution")
  #   stub_zammad(:get, "tickets/42", fixture: "zammad/ticket_resolution", overrides: { anonymous: true })
  #   stub_zammad(:post, "ticket_articles", status: 201, body: { id: 9 })
  #   stub_zammad(:get, "tickets/500", fixture: "zammad/backoffice_ticket", url: tenant.backoffice_url)
  #
  # `path` is relative to /api/v1/ and matches any query string, so callers do
  # not have to repeat the `?expand=true` the zammad_api gem appends.
  # `fixture` is a JSON file under test/fixtures/files/webmock/.
  def stub_zammad(method, path, fixture: nil, overrides: {}, body: nil, status: 200, url: ENV.fetch("TRIAGE_ZAMMAD_URL"))
    body = zammad_fixture(fixture, **overrides) if fixture
    body = body.to_json unless body.is_a?(String)

    stub_request(method, zammad_url(path, url: url))
      .with(query: hash_including({}))
      .to_return(status: status, body: body, headers: { "Content-Type" => "application/json" })
  end

  def zammad_fixture(fixture, **overrides)
    JSON.parse(file_fixture("webmock/#{fixture}.json").read).then do |data|
      data.is_a?(Hash) ? data.merge(overrides.deep_stringify_keys) : data
    end
  end

  def zammad_url(path, url: ENV.fetch("TRIAGE_ZAMMAD_URL"))
    File.join(url, "api/v1", path)
  end

  def zammad_not_found(model)
    { error: "Couldn't find #{model} with 'id'=0" }
  end
end
