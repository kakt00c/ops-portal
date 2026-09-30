require "application_system_test_case"

class Issues::UpdatesTest < ApplicationSystemTestCase
  setup do
    @author = users(:one)
    @issue = issues(:two) # resolution process issue authored by users(:one)
  end

  test "author adds an update with a photo" do
    login_as @author
    visit issue_path(@issue)

    click_on "Aktualizovať podnet"
    assert_text "Pri aktualizovaní podnetu je potrebné vždy pridať aj fotografiu"

    fill_in "issues_update_text", with: "Diera sa zväčšila, už je cez celý chodník."
    attach_file "new_files[]", file_fixture("graffiti-with-geo.jpg").to_s, visible: false
    assert_selector "figure.small-picture img"

    assert_no_enqueued_jobs(only: SyncIssueToTriageJob) do
      assert_enqueued_with(job: Issues::SyncEditableActivityToTriageJob) do
        click_on "Odoslať"

        within "#activities" do
          assert_text @author.display_name
          assert_text "Diera sa zväčšila, už je cez celý chodník."
          assert_text "Upraviť"
        end
      end
    end

    update = Issues::Update.last
    assert_equal @author, update.author
    assert_not update.resolves_issue?
    assert update.published
    assert_equal 1, update.attachments.count
    assert_equal "in_progress", @issue.reload.state.key
  end

  test "author marks own issue as resolved" do
    login_as @author
    visit issue_path(@issue)

    click_on "Označiť za vyriešený"
    assert_text "Označiť podnet za vyriešený"

    fill_in "issues_update_text", with: "Chodník je opravený, ďakujem."

    assert_enqueued_with(job: SyncIssueToTriageJob, args: [ @issue, { sync_activities: false } ]) do
      click_on "Odoslať"

      within "#activities" do
        assert_text "Chodník je opravený, ďakujem."
      end
    end

    assert_equal "resolved", @issue.reload.state.key
    assert Issues::Update.last.resolves_issue?
  end

  test "another user marking issue as resolved does not change its state" do
    login_as users(:legacy_citizen)
    visit issue_path(@issue)

    click_on "Označiť za vyriešený"
    fill_in "issues_update_text", with: "Videl som, že je to opravené."

    assert_no_enqueued_jobs(only: SyncIssueToTriageJob) do
      click_on "Odoslať"

      within "#activities" do
        assert_text "Videl som, že je to opravené."
      end
    end

    assert_equal "in_progress", @issue.reload.state.key
    assert Issues::Update.last.resolves_issue?
  end

  test "update without a photo shows validation error" do
    login_as @author
    visit issue_path(@issue)

    click_on "Aktualizovať podnet"
    fill_in "issues_update_text", with: "Bez fotky."
    click_on "Odoslať"

    assert_text "Fotografia pri overovaní podnetu je povinná položka"
    assert_equal 0, @issue.update_activities.count
  end

  test "author edits own update within editing window" do
    update = Issues::Update.new(text: "Pôvodný text", author: @author, published: true, legacy_id: 1)
    update.build_activity(issue: @issue, type: Issues::UpdateActivity)
    update.save!

    login_as @author
    visit issue_path(@issue)

    within "#issues_update_#{update.id}" do
      click_on "Upraviť"
    end

    assert_text "Upraviť aktualizáciu podnetu"
    fill_in "issues_update_text", with: "Opravený text"
    click_on "Uložiť zmeny"

    within "#activities" do
      assert_text "Opravený text"
      assert_no_text "Pôvodný text"
      assert_text "Komentár bol upravený"
    end

    assert_equal "Opravený text", update.reload.text
  end

  test "issue still in triage cannot be updated" do
    login_as @author
    visit issue_path(issues(:without_triage_external_id))

    assert_text "Pridať komentár"
    assert_no_text "Aktualizovať podnet"
    assert_no_text "Označiť za vyriešený"
  end
end
