require "test_helper"
require "test_helpers/triage_helper"

class Triage::ProcessNewActivityFromTriageJobTest < ActiveJob::TestCase
  include TriageHelper

  ALLOWED = [ :unknown_user_portal_comment, :user_portal_comment, :agent_portal_and_backoffice_comment, :agent_backoffice_comment, :agent_portal_comment ]

  def perform(responsible_subject, article:)
    client = Minitest::Mock.new
    client.expect :find_ticket_responsible_subject, { value: responsible_subject.id }, [ 42 ]
    client.expect :get_article, article, [ 42, 7 ], allowed_article_types: ALLOWED, responsible_subject: responsible_subject if responsible_subject.pro?
    Triage::ProcessNewActivityFromTriageJob.new.perform(42, 7, triage_zammad_client: client)
    assert_mock client
  end

  test "fires activity.created webhook with the article type" do
    assert_enqueued_with(job: Triage::FireWebhookJob) do
      perform responsible_subjects(:pro), article: triage_article(article_type: :user_portal_comment)
    end

    _client, _webhook_id, payload = last_enqueued_arguments(Triage::FireWebhookJob)
    assert_equal "activity.created", payload[:type]
    assert_equal({ subject_id: clients(:pro_backoffice).id, issue_id: 42, activity_id: 7, activity_type: :user_portal_comment }, payload[:data])
  end

  test "articles the responsible subject may not see are ignored" do
    assert_no_enqueued_jobs do
      perform responsible_subjects(:pro), article: nil
    end
  end

  test "non pro responsible subjects are skipped" do
    assert_no_enqueued_jobs do
      perform responsible_subjects(:one), article: nil
    end
  end

  test "pro responsible subject without clients raises" do
    clients(:pro_backoffice).destroy
    assert_raises(RuntimeError) { perform responsible_subjects(:pro), article: triage_article(article_type: :user_portal_comment) }
  end
end
