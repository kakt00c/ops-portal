require "test_helper"
require "test_helpers/triage_helper"

class Triage::SendNewIssueUpdateFromTriageToBackofficeJobTest < ActiveJob::TestCase
  include TriageHelper

  def perform(responsible_subject)
    client = Minitest::Mock.new
    client.expect :find_ticket_responsible_subject, { value: responsible_subject.id }, [ 42 ]
    Triage::SendNewIssueUpdateFromTriageToBackofficeJob.new.perform(42, triage_zammad_client: client)
    assert_mock client
  end

  test "fires issue.updated webhook for a pro responsible subject" do
    assert_enqueued_with(job: Triage::FireWebhookJob) do
      perform responsible_subjects(:pro)
    end

    _client, _webhook_id, payload = last_enqueued_arguments(Triage::FireWebhookJob)
    assert_equal "issue.updated", payload[:type]
    assert_equal 42, payload[:data][:issue_id]
  end

  test "non pro responsible subjects are skipped" do
    assert_no_enqueued_jobs { perform responsible_subjects(:one) }
  end

  test "pro responsible subject without clients raises" do
    clients(:pro_backoffice).destroy
    assert_raises(RuntimeError) { perform responsible_subjects(:pro) }
  end
end
