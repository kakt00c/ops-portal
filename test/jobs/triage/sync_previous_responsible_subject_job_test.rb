require "test_helper"

class Triage::SyncPreviousResponsibleSubjectJobTest < ActiveJob::TestCase
  test "syncs the previous responsible subject to the resolution ticket" do
    client = Minitest::Mock.new
    client.expect :sync_previous_responsible_subject!, nil, [ 601, responsible_subjects(:one) ]

    Triage::SyncPreviousResponsibleSubjectJob.new.perform(issues(:sent_to_responsible), responsible_subjects(:one), client: client)

    assert_mock client
  end

  test "does nothing for issues still in triage" do
    client = Minitest::Mock.new

    Triage::SyncPreviousResponsibleSubjectJob.new.perform(issues(:without_triage_external_id), responsible_subjects(:one), client: client)

    assert_mock client
  end
end
