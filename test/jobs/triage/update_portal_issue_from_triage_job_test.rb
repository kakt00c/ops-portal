require "test_helper"
require "test_helpers/triage_helper"

class Triage::UpdatePortalIssueFromTriageJobTest < ActiveJob::TestCase
  include TriageHelper

  test "copies ticket attributes and state onto the issue" do
    issue = issues(:two)
    ticket = triage_ticket(issue,
      ops_state: issues_states(:resolved),
      title: "Nový názov podnetu z triáže",
      description: "Nový popis podnetu z triáže, ktorý je dostatočne dlhý.",
      municipality: municipalities(:trencin),
      address_street: "Mierové námestie",
      address_lat: 48.894, address_lon: 18.044
    )

    Triage::UpdatePortalIssueFromTriageJob.new.perform(ticket)

    issue.reload
    assert_equal "resolved", issue.state.key
    assert_equal "Nový názov podnetu z triáže", issue.title
    assert_equal municipalities(:trencin), issue.municipality
    assert_equal "Mierové námestie", issue.address_street
    assert_in_delta 48.894, issue.latitude
    assert_equal "Bratislavský kraj", issue.address_region
    assert_equal "81101", issue.address_postcode
  end

  test "unresolved praise becomes privately resolved" do
    praise = issues(:praise_published)
    praise.update_columns(resolution_external_id: 800)
    ticket = triage_ticket(praise, ops_state: issues_states(:unresolved))

    Triage::UpdatePortalIssueFromTriageJob.new.perform(ticket)

    assert_equal "resolved_private", praise.reload.state.key
  end

  test "changed responsible subject is synced to the previous one" do
    issue = issues(:sent_to_responsible) # responsible_subjects(:one)
    ticket = triage_ticket(issue, responsible_subject: responsible_subjects(:two))

    assert_enqueued_with(job: Triage::SyncPreviousResponsibleSubjectJob, args: [ issue, responsible_subjects(:one) ]) do
      Triage::UpdatePortalIssueFromTriageJob.new.perform(ticket)
    end

    assert_equal responsible_subjects(:two), issue.reload.responsible_subject
  end

  test "unchanged responsible subject enqueues nothing" do
    issue = issues(:sent_to_responsible)

    assert_no_enqueued_jobs(only: Triage::SyncPreviousResponsibleSubjectJob) do
      Triage::UpdatePortalIssueFromTriageJob.new.perform(triage_ticket(issue))
    end
  end

  test "rejection creates a system note in triage" do
    issue = issues(:one)
    ticket = triage_ticket(issue, process_type: "portal_issue_triage", ops_state: issues_states(:rejected))

    assert_enqueued_with(job: Triage::CreateRejectionSystemNoteJob, args: [ issue ]) do
      Triage::UpdatePortalIssueFromTriageJob.new.perform(ticket)
    end

    assert_equal "rejected", issue.reload.state.key
  end

  test "sending to a responsible subject starts the resolution process" do
    issue = issues(:without_triage_external_id)
    issue.update_columns(triage_external_id: 900)
    ticket = triage_ticket(issue,
      process_type: "portal_issue_triage",
      ops_state: issues_states(:sent_to_responsible),
      responsible_subject: responsible_subjects(:one),
      triage_group: "Dobrovoľníci::Trenčín",
      triage_owner_id: 5
    )

    assert_enqueued_with(job: Triage::CreateIssueResolutionProcessTicketJob, args: [ issue, { triage_group: "Dobrovoľníci::Trenčín", triage_owner_id: 5 } ]) do
      Triage::UpdatePortalIssueFromTriageJob.new.perform(ticket)
    end
  end

  test "issue already in resolution process does not start another one" do
    issue = issues(:sent_to_responsible)

    assert_no_enqueued_jobs(only: Triage::CreateIssueResolutionProcessTicketJob) do
      Triage::UpdatePortalIssueFromTriageJob.new.perform(triage_ticket(issue))
    end
  end
end
