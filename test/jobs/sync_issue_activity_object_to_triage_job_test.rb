require "test_helper"

class SyncIssueActivityObjectToTriageJobTest < ActiveJob::TestCase
  setup do
    @issue = issues(:one)

    activity = Issues::UpdateActivity.create!(issue: @issue)

    @issue_update = Issues::Update.new(
      activity: activity,
      author: @issue.author,
      text: "Vyriešené!",
      resolves_issue: true,
      published: true
    )
    @issue_update.save!(validate: false)
  end

  test "creates verification ticket and auto-resolves issue in triage when author marks it resolved" do
    triage_zammad_client_mock = Minitest::Mock.new

    triage_zammad_client_mock.expect :create_ticket_from_issue_update!, 99, [ @issue_update ]

    triage_zammad_client_mock.expect :create_system_note!, nil, [
      @issue.resolution_external_id,
      "Stav podnetu bol zmenený na Vyriešený na základe informácie od zadávateľa podnetu."
    ], **{
      internal: false,
      sender: "Agent"
    }

    triage_zammad_client_mock.expect :update_ticket!, nil, [
      @issue.resolution_external_id,
      { "ops_state" => "resolved", "state" => "closed" }
    ]

    close_job_called = false
    Triage::CloseIssueUpdateTriageTicketJob.stub :perform_now, ->(update, state) {
      close_job_called = true if update == @issue_update && state == "accepted"
    } do
      SyncIssueActivityObjectToTriageJob.perform_now(
        issue: @issue,
        activity_object: @issue_update,
        client: triage_zammad_client_mock
      )
    end

    assert close_job_called, "Expected Triage::CloseIssueUpdateTriageTicketJob to be executed"
    assert_equal 99, @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end

  test "creates verification ticket but does not auto-resolve issue if author is different" do
    @issue_update.update!(author: users(:two))

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :create_ticket_from_issue_update!, 99, [ @issue_update ]

    SyncIssueActivityObjectToTriageJob.perform_now(
      issue: @issue,
      activity_object: @issue_update,
      client: triage_zammad_client_mock
    )

    assert_equal 99, @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end

  test "creates verification ticket but does not auto-resolve issue if resolves_issue is false" do
    @issue_update.update!(resolves_issue: false)

    triage_zammad_client_mock = Minitest::Mock.new
    triage_zammad_client_mock.expect :create_ticket_from_issue_update!, 99, [ @issue_update ]

    SyncIssueActivityObjectToTriageJob.perform_now(
      issue: @issue,
      activity_object: @issue_update,
      client: triage_zammad_client_mock
    )

    assert_equal 99, @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end

  test "does nothing if issue update already has external_id" do
    @issue_update.update!(external_id: 99, confirmed: false)

    triage_zammad_client_mock = Minitest::Mock.new

    SyncIssueActivityObjectToTriageJob.perform_now(
      issue: @issue,
      activity_object: @issue_update,
      client: triage_zammad_client_mock
    )

    assert_equal 99, @issue_update.reload.external_id
    assert_mock triage_zammad_client_mock
  end
end
