require "test_helper"

module Notifications
  class PublishIssueStateChangedJobTest < ActiveJob::TestCase
    include ActionMailer::TestHelper

    setup do
      @issue = issues(:one)
      @author_subscription = issue_subscriptions(:one)            # users(:one), author
      @inactive_subscription = issue_subscriptions(:one_legacy_citizen)
      @watcher_subscription = issue_subscriptions(:one_two)       # users(:two)
    end

    def perform(from, to)
      Notifications::PublishIssueStateChangedJob.perform_now(@issue, state_id_change: [ issues_states(from).id, issues_states(to).id ])
    end

    test "only active subscribers get notified when issue is resolved" do
      perform :waiting, :resolved

      assert_enqueued_emails 2
      assert_enqueued_email_with NotificationMailer, :issue_resolved, params: { subscription: @author_subscription }
      assert_enqueued_email_with NotificationMailer, :issue_resolved, params: { subscription: @watcher_subscription }
    end

    {
      unresolved: :issue_unresolved,
      referred: :issue_referred,
      closed: :issue_closed,
      duplicate: :issue_marked_as_duplicate,
      waiting_for_author: :issue_waiting_for_author
    }.each do |state, mail_method|
      test "#{state} notifies all active subscribers with #{mail_method}" do
        perform :in_progress, state

        assert_enqueued_emails 2
        assert_enqueued_email_with NotificationMailer, mail_method, params: { subscription: @author_subscription }
        assert_enqueued_email_with NotificationMailer, mail_method, params: { subscription: @watcher_subscription }
      end
    end

    test "rejected notifies only the author" do
      perform :waiting, :rejected

      assert_enqueued_emails 1
      assert_enqueued_email_with NotificationMailer, :issue_rejected, params: { subscription: @author_subscription }
    end

    test "states without a mail notify nobody" do
      perform :waiting, :in_progress
      perform :waiting, :sent_to_responsible

      assert_no_enqueued_emails
    end

    test "unarchiving notifies nobody" do
      perform :archived, :resolved

      assert_no_enqueued_emails
    end

    test "nothing happens without a state change" do
      Notifications::PublishIssueStateChangedJob.perform_now(@issue, state_id_change: [])

      assert_no_enqueued_emails
    end

    test "subscribers who turned off emails are skipped" do
      users(:one).update!(email_notifiable: false)

      perform :waiting, :resolved

      assert_enqueued_emails 1
      assert_enqueued_email_with NotificationMailer, :issue_resolved, params: { subscription: @watcher_subscription }
    end
  end
end
