require "test_helper"
require "test_helpers/triage_helper"

class Triage::ConnectDuplicateIssueFromTriageJobTest < ActiveJob::TestCase
  include TriageHelper

  setup do
    @issue = issues(:one)   # triage ticket 1, will become duplicate
    @parent = issues(:two)  # resolution ticket 3
    @ticket = triage_ticket(@issue, process_type: "portal_issue_triage", ops_state: issues_states(:duplicate))
    @client = Minitest::Mock.new
  end

  test "linked parent in resolution process: issue becomes duplicate and its content moves to the parent" do
    @client.expect :get_ticket_resolution_parent_links, [ 3 ], [ 1 ]
    @client.expect :get_ticket, triage_ticket(@parent), [ 3 ]
    @client.expect :create_system_note!, 1, [ 1, /duplicitný/ ], content_type: "text/html", internal: false, sender: "Agent"

    assert_enqueued_with(job: SyncIssueActivityObjectToTriageJob) do
      Triage::ConnectDuplicateIssueFromTriageJob.new.perform(@ticket, triage_zammad_client: @client)
    end

    assert_mock @client
    assert_equal "duplicate", @issue.reload.state.key

    comment = @parent.comments.order(:created_at).last
    assert_kind_of Issues::DuplicateIssueComment, comment
    assert_includes comment.text, @issue.description
    assert_equal @issue.author, comment.user_author

    # subscribers of the duplicate now follow the parent
    @issue.subscriptions.each do |subscription|
      assert subscription.subscriber.subscribed_to?(@parent), "#{subscription.subscriber.email} should follow the parent"
    end
    assert_equal 1, users(:two).issue_subscriptions.where(issue: @parent).count, "existing subscription is not duplicated"
  end

  test "without a linked parent the duplicate state is rejected back to triage" do
    @client.expect :get_ticket_resolution_parent_links, [], [ 1 ]
    @client.expect :update_ticket!, nil, [ 1 ], "ops_state" => "waiting"
    @client.expect :create_system_note!, 1, [ 1, /nalinkovaný pôvodný podnet/ ], internal: false

    assert_no_enqueued_jobs(only: SyncIssueActivityObjectToTriageJob) do
      Triage::ConnectDuplicateIssueFromTriageJob.new.perform(@ticket, triage_zammad_client: @client)
    end

    assert_mock @client
    assert_equal "waiting", @issue.reload.state.key
    assert_equal 0, @parent.comments.where(type: "Issues::DuplicateIssueComment").count
  end

  test "issue already marked as duplicate is not processed again" do
    @issue.update_columns(state_id: issues_states(:duplicate).id)
    @client.expect :get_ticket_resolution_parent_links, [ 3 ], [ 1 ]

    Triage::ConnectDuplicateIssueFromTriageJob.new.perform(@ticket, triage_zammad_client: @client)

    assert_mock @client
    assert_equal 0, @parent.comments.where(type: "Issues::DuplicateIssueComment").count
  end
end
