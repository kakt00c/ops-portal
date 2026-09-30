require "test_helper"

class Triage::UpdatePortalIssueUpdateFromTriageJobTest < ActiveJob::TestCase
  setup do
    @issue = issues(:two) # in_progress
    @update = Issues::Update.new(text: "Podnet je vyriešený", author: users(:one), published: true, resolves_issue: true, external_id: "700")
    @update.build_activity(issue: @issue, type: Issues::UpdateActivity)
    @update.attachments.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    @update.save!
  end

  def ticket(ops_state_key:, issue_resolved: "yes", description: "Podnet je vyriešený")
    { process_type: "portal_issue_verification", triage_identifier: "700", ops_state_key: ops_state_key, issue_resolved: issue_resolved, description: description, triage_group: "Dobrovoľníci::Trenčín" }
  end

  test "accepted verification resolves the issue and syncs back to triage" do
    assert_enqueued_with(job: SyncIssueToTriageJob, args: [ @issue ]) do
      assert_enqueued_with(job: Triage::CloseIssueUpdateTriageTicketJob, args: [ @update, "accepted" ]) do
        assert_enqueued_with(job: SyncIssueActivityObjectToTriageJob, args: [ { issue: @issue, activity_object: @update, triage_group: "Dobrovoľníci::Trenčín" } ]) do
          Triage::UpdatePortalIssueUpdateFromTriageJob.new.perform(ticket(ops_state_key: "accepted", description: "Upravený text z triáže"))
        end
      end
    end

    @update.reload
    assert @update.approved?
    assert @update.confirmed
    assert @update.published
    assert_equal "Upravený text z triáže", @update.text
    assert_equal "resolved", @issue.reload.state.key
  end

  test "accepted verification saying the issue is not resolved reopens a resolved issue" do
    @issue.update_columns(state_id: issues_states(:resolved).id)

    Triage::UpdatePortalIssueUpdateFromTriageJob.new.perform(ticket(ops_state_key: "accepted", issue_resolved: "no"))

    assert_equal "in_progress", @issue.reload.state.key
    assert_not @update.reload.resolves_issue?
  end

  test "accepted verification does not resolve archived or duplicate issues" do
    @issue.update_columns(state_id: issues_states(:duplicate).id)

    Triage::UpdatePortalIssueUpdateFromTriageJob.new.perform(ticket(ops_state_key: "accepted"))

    assert_equal "duplicate", @issue.reload.state.key
    assert @update.reload.approved?
  end

  test "rejected verification unpublishes the update and reopens the issue it had resolved" do
    @issue.update_columns(state_id: issues_states(:resolved).id)

    assert_enqueued_with(job: Triage::CloseIssueUpdateTriageTicketJob, args: [ @update, "rejected" ]) do
      assert_no_enqueued_jobs(only: SyncIssueToTriageJob) do
        Triage::UpdatePortalIssueUpdateFromTriageJob.new.perform(ticket(ops_state_key: "rejected"))
      end
    end

    @update.reload
    assert @update.rejected?
    assert_not @update.published
    assert_not @update.confirmed
    assert_equal "in_progress", @issue.reload.state.key
  end

  test "rejected verification of an unresolved issue leaves its state alone" do
    Triage::UpdatePortalIssueUpdateFromTriageJob.new.perform(ticket(ops_state_key: "rejected"))

    assert_equal "in_progress", @issue.reload.state.key
    assert @update.reload.rejected?
  end

  test "pending verification only syncs the update" do
    assert_no_enqueued_jobs(only: Triage::CloseIssueUpdateTriageTicketJob) do
      assert_enqueued_with(job: SyncIssueActivityObjectToTriageJob) do
        Triage::UpdatePortalIssueUpdateFromTriageJob.new.perform(ticket(ops_state_key: "open"))
      end
    end

    assert @update.reload.pending?
  end
end
