require "test_helper"

class Notifications::PublishNewIssueCommentJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @comment = issues_comments(:one_comment1) # by users(:one) on issues(:one)
    @issue = @comment.issue
    @author_subscription = issue_subscriptions(:one)            # users(:one)
    @inactive_subscription = issue_subscriptions(:one_legacy_citizen)
    @watcher_subscription = issue_subscriptions(:one_two)       # users(:two)
  end

  test "sends notifications only to active subscribers (except comment author)" do
    Notifications::PublishNewIssueCommentJob.perform_now(@comment)

    assert_enqueued_emails 1
    assert_enqueued_email_with NotificationMailer, :new_issue_user_comment, params: { subscription: @watcher_subscription }, args: [ @comment ]
  end

  test "does not send notifications to users who are not email notifiable" do
    @author_subscription.subscriber.update(email_notifiable: false)
    @watcher_subscription.subscriber.update(email_notifiable: false)

    Notifications::PublishNewIssueCommentJob.perform_now(@comment)

    assert_no_enqueued_emails
  end

  test "responsible subject reply uses its own mail and reaches the author" do
    reply = Issues::ResponsibleSubjectComment.new(text: "Odpoveď", responsible_subject_author: responsible_subjects(:one))
    reply.build_activity(issue: @issue, type: Issues::CommentActivity)
    reply.save!

    Notifications::PublishNewIssueCommentJob.perform_now(reply)

    assert_enqueued_emails 2
    assert_enqueued_email_with NotificationMailer, :new_issue_responsible_subject_comment, params: { subscription: @author_subscription }, args: [ reply ]
    assert_enqueued_email_with NotificationMailer, :new_issue_responsible_subject_comment, params: { subscription: @watcher_subscription }, args: [ reply ]
  end

  test "issue update is sent as a user comment to everyone but its author" do
    update = Issues::Update.new(text: "Aktualizácia", author: users(:one), published: true, legacy_id: 1)
    update.build_activity(issue: @issue, type: Issues::UpdateActivity)
    update.save!

    Notifications::PublishNewIssueCommentJob.perform_now(update)

    assert_enqueued_emails 1
    assert_enqueued_email_with NotificationMailer, :new_issue_user_comment, params: { subscription: @watcher_subscription }, args: [ update ]
  end

  test "comments on praises are not notified" do
    comment = Issues::UserComment.new(text: "Súhlasím", user_author: users(:two))
    comment.build_activity(issue: issues(:praise_waiting), type: Issues::CommentActivity)
    comment.save!

    Notifications::PublishNewIssueCommentJob.perform_now(comment)

    assert_no_enqueued_emails
  end
end
