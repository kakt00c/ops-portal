require "application_system_test_case"

class Issues::ResponsibleSubjectChangesTest < ApplicationSystemTestCase
  setup do
    @user = users(:responsible_subject)
    @issue = issues(:sent_to_responsible)
    login_via_magic_link(@user.email)
  end

  test "reassigning issue to another responsible subject" do
    other = responsible_subjects(:two)

    visit issue_path(@issue)
    click_on "Odstúpiť podnet"

    assert_text "Odstúpiť alebo preposlať podnet"
    choose "Preposlať inému zodpovednému subjektu"

    fill_in placeholder: "Vyhľadajte subjekt (napr. BVS, OLO)...", with: "BV"
    within ".dropdown-list" do
      click_on other.subject_name
    end

    fill_in "issues_responsible_subject_change_text", with: "Ide o vodovodné potrubie, patrí to BVS."

    assert_enqueued_with(job: SyncIssueToTriageJob, args: [ @issue, { sync_activities: false } ]) do
      assert_enqueued_with(job: SyncIssueActivityObjectToTriageJob) do
        click_on "Potvrdiť"

        within "#activities" do
          assert_text "Ide o vodovodné potrubie, patrí to BVS."
        end
      end
    end

    @issue.reload
    assert_equal other, @issue.responsible_subject
    assert_equal "sent_to_responsible", @issue.state.key

    change = Issues::ResponsibleSubjectChange.last
    assert change.reassignment?
    assert_equal @user.responsible_subject, change.responsible_subject_author
    assert_equal @user, change.user_author

    # after reassignment the previous subject is no longer responsible
    assert_no_text "Pridať komentár"
  end

  test "referring issue keeps responsible subject and sets referred state" do
    visit issue_path(@issue)
    click_on "Odstúpiť podnet"

    choose "Odstúpiť podnet"
    fill_in "issues_responsible_subject_change_text", with: "Riešime to s krajským úradom."

    assert_enqueued_with(job: SyncIssueToTriageJob) do
      click_on "Potvrdiť"

      within "#activities" do
        assert_text "Riešime to s krajským úradom."
      end
    end

    @issue.reload
    assert_equal responsible_subjects(:one), @issue.responsible_subject
    assert_equal "referred", @issue.state.key
    assert Issues::ResponsibleSubjectChange.last.refer?
  end

  test "reassignment without a subject shows validation error" do
    visit issue_path(@issue)
    click_on "Odstúpiť podnet"

    choose "Preposlať inému zodpovednému subjektu"
    fill_in "issues_responsible_subject_change_text", with: "Chýba subjekt."
    click_on "Potvrdiť"

    assert_text "Zodpovedný subjekt je povinná položka"
    assert_equal "sent_to_responsible", @issue.reload.state.key
  end

  test "change without a comment shows validation error" do
    visit issue_path(@issue)
    click_on "Odstúpiť podnet"

    choose "Odstúpiť podnet"
    click_on "Potvrdiť"

    assert_text "Text komentára je povinná položka"
    assert_equal "sent_to_responsible", @issue.reload.state.key
  end
end
