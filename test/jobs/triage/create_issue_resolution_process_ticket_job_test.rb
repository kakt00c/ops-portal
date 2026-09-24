require "test_helper"

class Triage::CreateIssueResolutionProcessTicketJobTest < ActiveJob::TestCase
  setup do
    @issue = issues(:one)
    @issue.update_columns(
      title: "A valid issue title",
      description: "A valid issue description that is long enough to pass validation"
    )
    @issue_number = "R-#{@issue.id.to_s.rjust(4, "0")}"
  end

  test "creates resolution ticket and updates issue with returned ID" do
    mock_client = Minitest::Mock.new
    mock_client.expect :create_ticket_from_issue!, 99, [ @issue ],
      issue_number: @issue_number, process_type: "portal_issue_resolution", group: "TestGroup"
    mock_client.expect :link_tickets!, nil, [],
      parent_ticket_id: @issue.triage_external_id, child_ticket_id: 99
    mock_client.expect :create_system_note!, 1, [ @issue.triage_external_id, String ],
      content_type: "text/html"
    mock_client.expect :close_ticket!, nil, [ @issue.triage_external_id ]

    Triage::CreateIssueResolutionProcessTicketJob.new.perform(
      @issue,
      triage_group: "TestGroup",
      triage_owner_id: nil,
      triage_zammad_client: mock_client
    )

    assert_equal 99, @issue.reload.resolution_external_id
    mock_client.verify
  end

  test "recovers resolution ticket ID when ticket already exists in Zammad" do
    existing_ticket = OpenStruct.new(id: 77, number: @issue_number)
    search_stub = Object.new
    search_stub.define_singleton_method(:search) { |**| [ existing_ticket ] }
    inner_client = Object.new
    inner_client.define_singleton_method(:ticket) { search_stub }

    client_stub = Object.new
    client_stub.define_singleton_method(:create_ticket_from_issue!) { |*, **| raise RuntimeError, "This object already exists" }
    client_stub.define_singleton_method(:client) { inner_client }
    client_stub.define_singleton_method(:link_tickets!) { |**| }
    client_stub.define_singleton_method(:create_system_note!) { |*, **| 1 }
    client_stub.define_singleton_method(:close_ticket!) { |*| }

    Triage::CreateIssueResolutionProcessTicketJob.new.perform(
      @issue,
      triage_group: "TestGroup",
      triage_owner_id: nil,
      triage_zammad_client: client_stub
    )

    assert_equal 77, @issue.reload.resolution_external_id
  end

  test "retry after issue.update! succeeded: recovers ticket ID and completes remaining steps" do
    # Simulate a prior run where create_ticket_from_issue! and issue.update! succeeded
    # but link_tickets! or later failed. The issue already has resolution_external_id set.
    existing_ticket = OpenStruct.new(id: @issue.resolution_external_id, number: @issue_number)
    search_stub = Object.new
    search_stub.define_singleton_method(:search) { |**| [ existing_ticket ] }
    inner_client = Object.new
    inner_client.define_singleton_method(:ticket) { search_stub }

    link_called = false
    note_called = false
    close_called = false

    client_stub = Object.new
    client_stub.define_singleton_method(:create_ticket_from_issue!) { |*, **| raise RuntimeError, "This object already exists" }
    client_stub.define_singleton_method(:client) { inner_client }
    client_stub.define_singleton_method(:link_tickets!) { |**| link_called = true }
    client_stub.define_singleton_method(:create_system_note!) { |*, **| note_called = true; 1 }
    client_stub.define_singleton_method(:close_ticket!) { |*| close_called = true }

    Triage::CreateIssueResolutionProcessTicketJob.new.perform(
      @issue,
      triage_group: "TestGroup",
      triage_owner_id: nil,
      triage_zammad_client: client_stub
    )

    assert_equal @issue.resolution_external_id, @issue.reload.resolution_external_id
    assert link_called, "link_tickets! should still be called on retry"
    assert note_called, "create_system_note! should still be called on retry"
    assert close_called, "close_ticket! should still be called on retry"
  end

  test "retry after all steps completed: job completes without raising" do
    existing_ticket = OpenStruct.new(id: @issue.resolution_external_id, number: @issue_number)
    search_stub = Object.new
    search_stub.define_singleton_method(:search) { |**| [ existing_ticket ] }
    inner_client = Object.new
    inner_client.define_singleton_method(:ticket) { search_stub }

    client_stub = Object.new
    client_stub.define_singleton_method(:create_ticket_from_issue!) { |*, **| raise RuntimeError, "This object already exists" }
    client_stub.define_singleton_method(:client) { inner_client }
    client_stub.define_singleton_method(:link_tickets!) { |**| }
    client_stub.define_singleton_method(:create_system_note!) { |*, **| 1 }
    client_stub.define_singleton_method(:close_ticket!) { |*| }

    assert_nothing_raised do
      Triage::CreateIssueResolutionProcessTicketJob.new.perform(
        @issue,
        triage_group: "TestGroup",
        triage_owner_id: nil,
        triage_zammad_client: client_stub
      )
    end

    assert_equal @issue.resolution_external_id, @issue.reload.resolution_external_id
  end
end
