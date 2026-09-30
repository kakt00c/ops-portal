require "test_helper"
require "test_helpers/triage_helper"

class Triage::SyncTicketUpdateFromTriageJobTest < ActiveJob::TestCase
  include TriageHelper

  def perform_with(ticket)
    client = Minitest::Mock.new
    client.expect :get_ticket, ticket, [ 42 ]
    Triage::SyncTicketUpdateFromTriageJob.new.perform(42, triage_zammad_client: client)
    assert_mock client
  end

  test "issue tickets are handed to the issue update job" do
    ticket = triage_ticket(issues(:two))

    assert_enqueued_with(job: Triage::UpdatePortalIssueFromTriageJob, args: [ ticket ]) do
      perform_with ticket
    end
  end

  test "issue tickets marked as duplicate are handed to the duplicate job" do
    ticket = triage_ticket(issues(:one), process_type: "portal_issue_triage", ops_state: issues_states(:duplicate))

    assert_enqueued_with(job: Triage::ConnectDuplicateIssueFromTriageJob, args: [ ticket ]) do
      assert_no_enqueued_jobs(only: Triage::UpdatePortalIssueFromTriageJob) do
        perform_with ticket
      end
    end
  end

  test "verification tickets are handed to the issue update update job" do
    ticket = { process_type: "portal_issue_verification", triage_identifier: 42, ops_state_key: "accepted" }

    assert_enqueued_with(job: Triage::UpdatePortalIssueUpdateFromTriageJob, args: [ ticket ]) do
      perform_with ticket
    end
  end

  test "unknown process types and missing tickets raise" do
    assert_raises(RuntimeError) { perform_with({ process_type: "something_else" }) }
    assert_raises(RuntimeError) { perform_with(nil) }
  end
end
