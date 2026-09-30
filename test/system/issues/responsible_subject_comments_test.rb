require "application_system_test_case"

class Issues::ResponsibleSubjectCommentsTest < ApplicationSystemTestCase
  setup do
    @user = users(:responsible_subject)
    login_via_magic_link(@user.email)
  end

  test "first reply moves issue from sent to responsible into in progress" do
    issue = issues(:sent_to_responsible)
    visit issue_path(issue)

    assert_text "Zaslaný zodpovednému"
    click_on "Pridať komentár"

    assert_text "Po pridaní prvého komentára sa automaticky zmení stav podnetu."
    fill_in "issues_responsible_subject_comment_text", with: "Ďakujeme, chodník opravíme budúci týždeň."

    assert_enqueued_with(job: SyncIssueToTriageJob, args: [ issue, { sync_activities: false } ]) do
      assert_enqueued_with(job: Issues::SyncEditableActivityToTriageJob) do
        click_on "Odoslať"

        within "#activities" do
          assert_text @user.responsible_subject.subject_name
          assert_text "Ďakujeme, chodník opravíme budúci týždeň."
          assert_text "Upraviť"
        end
      end
    end

    assert_equal "in_progress", issue.reload.state.key
    comment = issue.comments.last
    assert_kind_of Issues::ResponsibleSubjectComment, comment
    assert_equal @user.responsible_subject, comment.responsible_subject_author
  end

  test "reply on issue already in progress keeps its state" do
    issue = issues(:legacy1)
    visit issue_path(issue)

    click_on "Pridať komentár"
    fill_in "issues_responsible_subject_comment_text", with: "Pracujeme na tom."

    assert_no_enqueued_jobs(only: SyncIssueToTriageJob) do
      click_on "Odoslať"

      within "#activities" do
        assert_text "Pracujeme na tom."
      end
    end

    assert_equal "in_progress", issue.reload.state.key
  end

  test "marking issue as resolved changes state and hides resolution buttons" do
    issue = issues(:sent_to_responsible)
    visit issue_path(issue)

    click_on "Označiť za vyriešený"

    assert_text "Pri označení podnetu za vyriešený môžete pridať fotografiu"
    fill_in "issues_responsible_subject_comment_text", with: "Chodník bol opravený."

    assert_enqueued_with(job: SyncIssueToTriageJob, args: [ issue, { sync_activities: false } ]) do
      click_on "Označiť"

      within "#activities" do
        assert_text "Chodník bol opravený."
      end
    end

    assert_equal "marked_as_resolved", issue.reload.state.key
  end

  test "empty reply shows validation error" do
    visit issue_path(issues(:sent_to_responsible))

    click_on "Pridať komentár"
    click_on "Odoslať"

    assert_text "Text je povinná položka"
    assert_equal "sent_to_responsible", issues(:sent_to_responsible).reload.state.key
  end

  test "responsible subject can edit own comment within editing window" do
    issue = issues(:legacy1)
    comment = Issues::ResponsibleSubjectComment.new(text: "Pôvodná odpoveď", responsible_subject_author: @user.responsible_subject)
    comment.build_activity(issue: issue, type: Issues::CommentActivity)
    comment.save!

    visit issue_path(issue)

    within "#activities" do
      click_on "Upraviť"
    end

    assert_text "Upraviť komentár"
    fill_in "issues_responsible_subject_comment_text", with: "Opravená odpoveď"
    click_on "Odoslať"

    within "#activities" do
      assert_text "Opravená odpoveď"
      assert_no_text "Pôvodná odpoveď"
      assert_text "Komentár bol upravený"
    end

    assert_equal "Opravená odpoveď", comment.reload.text
    assert_not_nil comment.last_edited_at
  end

  test "resolved issue offers only a comment" do
    visit issue_path(issues(:resolved_by_responsible))

    assert_text "Pridať komentár"
    assert_no_text "Odstúpiť podnet"
    assert_no_text "Označiť za vyriešený"
  end

  test "responsible subject cannot act on issue owned by another subject" do
    issue = issues(:sent_to_responsible)
    issue.update_columns(responsible_subject_id: responsible_subjects(:two).id)

    visit issue_path(issue)

    assert_no_text "Pridať komentár"
    assert_no_text "Odstúpiť podnet"
  end
end
