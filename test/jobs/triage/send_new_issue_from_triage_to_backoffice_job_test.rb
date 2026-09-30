require "test_helper"
require "test_helpers/triage_helper"

class Triage::SendNewIssueFromTriageToBackofficeJobTest < ActiveJob::TestCase
  include TriageHelper

  def perform(responsible_subject)
    client = Minitest::Mock.new
    client.expect :find_ticket_responsible_subject, { value: responsible_subject.id }, [ 42 ]
    Triage::SendNewIssueFromTriageToBackofficeJob.new.perform(42, triage_zammad_client: client)
    assert_mock client
  end

  test "fires issue.created webhook to every client of a pro responsible subject" do
    assert_enqueued_with(job: Triage::FireWebhookJob) do
      perform responsible_subjects(:pro)
    end

    client, _webhook_id, payload = last_enqueued_arguments(Triage::FireWebhookJob)
    assert_equal clients(:pro_backoffice), client
    assert_equal "issue.created", payload[:type]
    assert_equal({ subject_id: client.id, issue_id: 42 }, payload[:data])
  end

  test "non pro responsible subjects are skipped" do
    assert_no_enqueued_jobs do
      perform responsible_subjects(:one)
    end
  end

  test "pro responsible subject without clients raises" do
    clients(:pro_backoffice).destroy

    assert_raises(RuntimeError) { perform responsible_subjects(:pro) }
  end
end
