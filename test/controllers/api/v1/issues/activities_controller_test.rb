require "test_helper"
require "test_helpers/api_helper"
require "test_helpers/triage_helper"

class Api::V1::Issues::ActivitiesControllerTest < ActionDispatch::IntegrationTest
  include ApiHelper
  include TriageHelper

  ACTIVITY_SCHEMA = {
    triage_identifier: Integer, activity_type: String, author: [ Hash, NilClass ], content_type: String, body: String,
    created_at: String, updated_at: String,
    attachments: [ { triage_identifier: Integer, filename: String, content_type: String, data64: String } ]
  }.freeze

  setup do
    @client, @key = api_client_with_key
    @responsible_subject = @client.responsible_subject
    @token = api_token(@client, @key)
    @issue = issues(:sent_to_responsible)
    @issue.update_columns(responsible_subject_id: @responsible_subject.id)
    @ticket = triage_ticket(@issue)
  end

  test "show returns an activity of the issue" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ]
    zammad.expect :get_article, triage_article(article_type: :agent_backoffice_comment, body: "Odpoveď", attachments: [ triage_attachment ]), [ "601", "7" ], responsible_subject: @responsible_subject

    with_zammad_client(zammad) do
      get api_v1_issue_activity_url(601, 7), headers: api_headers(@token)
    end

    assert_response :success
    assert_mock zammad
    assert_json_schema ACTIVITY_SCHEMA, response.parsed_body
    assert_equal "agent_backoffice_comment", response.parsed_body["activity_type"]
    assert_equal "Odpoveď", response.parsed_body["body"]
  end

  test "show of an activity the responsible subject may not see is not found" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ]
    zammad.expect :get_article, nil, [ "601", "7" ], responsible_subject: @responsible_subject

    with_zammad_client(zammad) do
      get api_v1_issue_activity_url(601, 7), headers: api_headers(@token)
    end

    assert_response :not_found
  end

  test "create adds an article to the triage ticket and returns its id" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ]
    zammad.expect :create_article_from_api!, 99, [ @responsible_subject.external_id, "601", ActionController::Parameters ]

    with_zammad_client(zammad) do
      post api_v1_issue_activities_url(601),
        params: { activity: { content_type: "text/plain", body: "Riešime", attachments: [ { filename: "a.jpg", content_type: "image/jpeg", data64: "AAAA" } ] } }.to_json,
        headers: api_headers(@token).merge("Content-Type" => "application/json")
    end

    assert_response :success
    assert_mock zammad
    assert_equal({ "activity_id" => 99 }, response.parsed_body)
  end

  test "create registers the responsible subject in triage first when it has no external id" do
    @responsible_subject.update_columns(external_id: nil)
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, @ticket, [ "601" ]
    zammad.expect :create_responsible_subject!, "5555", [ @responsible_subject ]
    zammad.expect :create_article_from_api!, 100, [ "5555", "601", ActionController::Parameters ]

    with_zammad_client(zammad) do
      post api_v1_issue_activities_url(601), params: { activity: { content_type: "text/plain", body: "Riešime" } }, headers: api_headers(@token)
    end

    assert_response :success
    assert_mock zammad
    assert_equal "5555", @responsible_subject.reload.external_id
  end

  test "create on a ticket of another responsible subject is not found" do
    zammad = Minitest::Mock.new
    zammad.expect :get_ticket, triage_ticket(issues(:legacy1)), [ "3" ]

    with_zammad_client(zammad) do
      post api_v1_issue_activities_url(3), params: { activity: { body: "x" } }, headers: api_headers(@token)
    end

    assert_response :not_found
  end

  test "requests without token are rejected" do
    get api_v1_issue_activity_url(601, 7)
    assert_response :bad_request
  end
end
