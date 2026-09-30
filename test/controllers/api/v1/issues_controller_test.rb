require "test_helper"
require "test_helpers/api_helper"
require "test_helpers/triage_helper"

class Api::V1::IssuesControllerTest < ActionDispatch::IntegrationTest
  include ApiHelper
  include TriageHelper

  ISSUE_SCHEMA = {
    triage_identifier: Integer, ops_issue_identifier: Integer, ops_state: String, title: String,
    responsible_subject: { label: [ String, NilClass ], value: [ Integer, NilClass ] },
    responsible_subject_changed_at: [ String, NilClass ], author: [ Hash, NilClass ], issue_type: String,
    category: String, subcategory: [ String, NilClass ], subtype: [ String, NilClass ],
    address_municipality: String, address_postcode: [ String, NilClass ], address_street: [ String, NilClass ],
    address_house_number: [ String, NilClass ], likes_count: Integer, address_lat: Float, address_lon: Float,
    portal_url: String, created_at: String, resolution_started_at: [ String, NilClass ], updated_at: String,
    activities: [ {
      triage_identifier: Integer, activity_type: String, uuid: String, author: [ Hash, NilClass ], content_type: String,
      body: String, created_at: String, updated_at: String,
      attachments: [ { triage_identifier: Integer, filename: String, content_type: String, data64: String } ]
    } ]
  }.freeze

  setup do
    @client, @key = api_client_with_key
    @responsible_subject = @client.responsible_subject
    @token = api_token(@client, @key)
    @issue = issues(:sent_to_responsible)
    @issue.update_columns(responsible_subject_id: @responsible_subject.id)
  end

  # authentication

  test "request without token is a bad request" do
    get api_v1_issues_url
    assert_response :bad_request
    assert_equal "no_credentials", response.parsed_body["message"]
  end

  test "malformed token is unauthorized" do
    get api_v1_issues_url, headers: api_headers("not.a.token")
    assert_response :unauthorized
    assert_equal 'Token realm="API"', response.headers["WWW-Authenticate"]
    assert_kind_of String, response.parsed_body["message"]
  end

  test "token signed with another key is unauthorized" do
    get api_v1_issues_url, headers: api_headers(api_token(@client, OpenSSL::PKey::EC.generate("prime256v1")))
    assert_response :unauthorized
  end

  test "expired token is unauthorized" do
    get api_v1_issues_url, headers: api_headers(api_token(@client, @key, exp: 1.minute.ago.to_i))
    assert_response :unauthorized
  end

  test "token valid for too long is unauthorized" do
    get api_v1_issues_url, headers: api_headers(api_token(@client, @key, exp: 1.hour.from_now.to_i))
    assert_response :unauthorized
  end

  test "token for unknown client is unauthorized" do
    get api_v1_issues_url, headers: api_headers(api_token(@client, @key, sub: 0))
    assert_response :unauthorized
  end

  test "token can also be passed as a query parameter" do
    get api_v1_issues_url(token: @token)
    assert_response :success
  end

  # index

  test "index lists issues of the client's responsible subject in resolution process" do
    triage_only = issues(:legacy1)
    triage_only.update_columns(responsible_subject_id: @responsible_subject.id)

    get api_v1_issues_url, headers: api_headers(@token)

    assert_response :success
    assert_json_schema({ triage_identifier: Integer, ops_issue_identifier: Integer, ops_state: String }, response.parsed_body.first)
    assert_equal [ @issue.id ], response.parsed_body.map { |i| i["ops_issue_identifier"] }
    assert_equal({ "triage_identifier" => 601, "ops_issue_identifier" => @issue.id, "ops_state" => "sent_to_responsible" }, response.parsed_body.first)
  end

  test "index with all=true includes issues still in triage" do
    triage_only = issues(:legacy1)
    triage_only.update_columns(responsible_subject_id: @responsible_subject.id)

    get api_v1_issues_url(all: "true"), headers: api_headers(@token)

    ids = response.parsed_body.map { |i| i["ops_issue_identifier"] }
    assert_includes ids, triage_only.id
    assert_nil response.parsed_body.find { |i| i["ops_issue_identifier"] == triage_only.id }["triage_identifier"]
  end

  test "index can be filtered by state" do
    issues(:resolved_by_responsible).update_columns(responsible_subject_id: @responsible_subject.id)

    get api_v1_issues_url(ops_state: "resolved"), headers: api_headers(@token)

    assert_equal [ issues(:resolved_by_responsible).id ], response.parsed_body.map { |i| i["ops_issue_identifier"] }
  end

  # show

  def ticket_with_activities
    triage_ticket(@issue, responsible_subject_changed_at: nil, resolution_started_at: @issue.resolution_started_at).merge(
      activities: [ triage_article(article_type: :agent_portal_and_backoffice_comment, body: "Text", attachments: [ triage_attachment ]) ]
    )
  end

  test "show returns the issue with its activities" do
    ticket = ticket_with_activities
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, ticket, [ "601" ]
    zammad.expect :get_ticket, ticket, [ "601" ], responsible_subject: @responsible_subject,
      allowed_article_types: [ :agent_portal_and_backoffice_comment, :agent_backoffice_comment, :responsible_subject_portal_and_backoffice_comment ], expand: true

    with_zammad_client(zammad) do
      get api_v1_issue_url(601), headers: api_headers(@token)
    end

    assert_response :success
    assert_mock zammad
    assert_json_schema ISSUE_SCHEMA, response.parsed_body
    assert_equal @issue.id, response.parsed_body["ops_issue_identifier"]
    assert_equal "sent_to_responsible", response.parsed_body["ops_state"]
    assert_equal @responsible_subject.subject_name, response.parsed_body.dig("responsible_subject", "label")
    assert_equal "photo.jpg", response.parsed_body.dig("activities", 0, "attachments", 0, "filename")
  end

  test "show parameters widen or narrow the returned activity types" do
    ticket = ticket_with_activities
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, ticket, [ "601" ]
    zammad.expect :get_ticket, ticket, [ "601" ], responsible_subject: @responsible_subject,
      allowed_article_types: [ :agent_portal_and_backoffice_comment, :agent_backoffice_comment, :unknown_user_portal_comment, :user_portal_comment, :agent_portal_comment ], expand: false

    with_zammad_client(zammad) do
      get api_v1_issue_url(601, include_customer_activities: "true", exclude_responsible_subject_articles: "true", expand: "false"), headers: api_headers(@token)
    end

    assert_response :success
    assert_mock zammad
  end

  test "show of a ticket belonging to another responsible subject is not found" do
    ticket = triage_ticket(issues(:legacy1)) # responsible_subjects(:one)
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, ticket, [ "3" ]

    with_zammad_client(zammad) do
      get api_v1_issue_url(3), headers: api_headers(@token)
    end

    assert_response :not_found
  end

  test "show of an unknown ticket is not found" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, nil, [ "999" ]

    with_zammad_client(zammad) do
      get api_v1_issue_url(999), headers: api_headers(@token)
    end

    assert_response :not_found
  end

  # update

  test "update forwards allowed attributes to the triage ticket" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, triage_ticket(@issue), [ "601" ]
    zammad.expect :update_ticket!, true, [ "601", ActionController::Parameters ]

    with_zammad_client(zammad) do
      put api_v1_issue_url(601), params: { issue: { ops_state: "in_progress", investment: "yes", not_allowed: "x" } }, headers: api_headers(@token)
    end

    assert_response :ok
    assert_mock zammad
  end

  test "update without issue params is a bad request" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, triage_ticket(@issue), [ "601" ]

    with_zammad_client(zammad) do
      put api_v1_issue_url(601), params: {}, headers: api_headers(@token)
    end

    assert_response :bad_request
  end

  # search (no authentication)

  test "should get search" do
    get search_api_v1_issues_url, params: { portal_identifier: issues(:one).id }
    assert_response :success
    assert_equal({ id: issues(:one).resolution_external_id }.to_json, response.body)
  end

  test "search should return not found for invalid portal identifier" do
    get search_api_v1_issues_url, params: { portal_identifier: "nonexistent" }
    assert_response :not_found
  end

  test "search should return not found for missing portal identifier" do
    get search_api_v1_issues_url, params: { portal_identifier: nil }
    assert_response :not_found
  end

  test "search should return not found for empty params" do
    get search_api_v1_issues_url
    assert_response :not_found
  end

  test "search should return not found for non-triage process issue" do
    get search_api_v1_issues_url, params: { portal_identifier: issues(:without_triage_external_id).id }
    assert_response :not_found
  end
end
