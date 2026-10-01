require "test_helper"

class Triage::CreateRejectionSystemNoteJobTest < ActiveJob::TestCase
  test "notes the rejection on the resolution ticket when there is one" do
    client = Minitest::Mock.new
    client.expect :create_system_note!, 1, [ 3, "Podnet bol zamietnutý." ]

    Triage::CreateRejectionSystemNoteJob.new.perform(issues(:two), triage_zammad_client: client)

    assert_mock client
  end

  test "notes the rejection on the triage ticket otherwise" do
    issue = issues(:without_triage_external_id)
    issue.update_columns(triage_external_id: 900)
    client = Minitest::Mock.new
    client.expect :create_system_note!, 1, [ 900, "Podnet bol zamietnutý." ]

    Triage::CreateRejectionSystemNoteJob.new.perform(issue, triage_zammad_client: client)

    assert_mock client
  end
end
