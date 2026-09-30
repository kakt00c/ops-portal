require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  setup do
    @issue = issues(:one)
    @author_subscription = issue_subscriptions(:one)       # users(:one) is the author of issues(:one)
    @watcher_subscription = issue_subscriptions(:one_two)  # users(:two) only watches issues(:one)
  end

  test "every mail goes to the subscriber with issue subject and unsubscribe headers" do
    mail = NotificationMailer.with(subscription: @watcher_subscription).issue_resolved

    assert_equal [ users(:two).email ], mail.to
    assert_equal "Odkaz pre starostu | #{@issue.title} (Podnet ##{@issue.id})", mail.subject
    assert_equal "<#{unsubscribe_global_subscriptions_url(token: users(:two).email_global_unsubscribe_token)}>", mail.header["List-Unsubscribe"].value
    assert_equal "List-Unsubscribe=One-Click", mail.header["List-Unsubscribe-Post"].value
    assert_includes mail.body.encoded, issue_url(@issue)
    assert_includes mail.body.encoded, unsubscribe_subscriptions_url(token: @watcher_subscription.email_unsubscribe_token)
  end

  test "subject names the type of the record" do
    question = issues(:one).dup.tap { |i| i.issue_type = :question; i.triage_external_id = nil; i.resolution_external_id = nil; i.photos.attach(active_storage_blobs(:issue_photo)); i.save! }
    subscription = question.subscriptions.create!(subscriber: users(:two))
    assert_equal "Odkaz pre starostu | #{question.title} (Otázka ##{question.id})", NotificationMailer.with(subscription: subscription).issue_resolved.subject

    praise_subscription = issue_subscriptions(:praise)
    praise = praise_subscription.issue
    assert_equal "Odkaz pre starostu | #{praise.title} (Pochvala ##{praise.id})", NotificationMailer.with(subscription: praise_subscription).praise_accepted.subject
  end

  test "issue_accepted" do
    mail = NotificationMailer.with(subscription: @author_subscription).issue_accepted
    assert_includes mail.body.encoded, "bol zverejnený a odoslaný zodpovedným pracovníkom"
  end

  test "praise_accepted" do
    mail = NotificationMailer.with(subscription: issue_subscriptions(:praise)).praise_accepted
    assert_includes mail.body.encoded, "bola schválená a preposlaná príslušným adresátom"
  end

  test "issue_resolved tells the author and the watcher differently" do
    assert_includes NotificationMailer.with(subscription: @author_subscription).issue_resolved.body.encoded, "Váš podnet"
    assert_includes NotificationMailer.with(subscription: @watcher_subscription).issue_resolved.body.encoded, "že podnet"
  end

  test "issue_unresolved" do
    assert_includes NotificationMailer.with(subscription: @author_subscription).issue_unresolved.body.encoded, "označujeme ako neriešený"
    assert_includes NotificationMailer.with(subscription: @watcher_subscription).issue_unresolved.body.encoded, "označujeme ako neriešený"
  end

  test "issue_referred" do
    assert_includes NotificationMailer.with(subscription: @author_subscription).issue_referred.body.encoded, "bol odstúpený zodpovednému subjektu"
  end

  test "issue_closed" do
    assert_includes NotificationMailer.with(subscription: @author_subscription).issue_closed.body.encoded, "bol uzavretý"
  end

  test "issue_rejected for issue and for praise" do
    assert_includes NotificationMailer.with(subscription: @author_subscription).issue_rejected.body.encoded, "Váš podnet"
    assert_includes NotificationMailer.with(subscription: @author_subscription).issue_rejected.body.encoded, "bol zamietnutý"
    assert_includes NotificationMailer.with(subscription: issue_subscriptions(:praise)).issue_rejected.body.encoded, "Vaša pochvala"
  end

  test "issue_marked_as_duplicate" do
    assert_includes NotificationMailer.with(subscription: @watcher_subscription).issue_marked_as_duplicate.body.encoded, "označený ako duplikát"
  end

  test "issue_waiting_for_author" do
    assert_includes NotificationMailer.with(subscription: @author_subscription).issue_waiting_for_author.body.encoded, "sú potrebné doplňujúce informácie"
  end

  test "new_issue_user_comment includes author and text" do
    comment = issues_comments(:one_comment1)
    comment.update!(text: "Toto je nový komentár.")

    mail = NotificationMailer.with(subscription: @watcher_subscription).new_issue_user_comment(comment)

    assert_includes mail.body.encoded, "pribudol nový komentár"
    assert_includes mail.body.encoded, comment.author_display_name
    assert_includes mail.body.encoded, "Toto je nový komentár."
  end

  test "new_issue_responsible_subject_comment" do
    comment = Issues::ResponsibleSubjectComment.new(text: "Odpoveď mesta", responsible_subject_author: responsible_subjects(:one))
    comment.build_activity(issue: @issue, type: Issues::CommentActivity)
    comment.save!

    mail = NotificationMailer.with(subscription: @author_subscription).new_issue_responsible_subject_comment(comment)

    assert_includes mail.body.encoded, "pribudla nová odpoveď od samosprávy"
  end

  test "new_issue_update and new_issue_verification are not implemented yet" do
    assert_raises(NotImplementedError) { NotificationMailer.with(subscription: @author_subscription).new_issue_update.body }
    assert_raises(NotImplementedError) { NotificationMailer.with(subscription: @author_subscription).new_issue_verification.body }
  end
end
