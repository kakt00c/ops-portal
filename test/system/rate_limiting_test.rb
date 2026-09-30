require "application_system_test_case"

class RateLimitingTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    login(users(:one).email, "password")
  end

  test "user is redirected when exceeding issue creation limit" do
    10.times do |i|
      Issue.create!(
        photos: [ active_storage_blobs(:issue_photo) ],
        title: "Test Issue #{i}",
        description: "Description for test issue #{i}",
        category: issues_categories(:one),
        state: Issues::State.find_by!(key: "waiting"),
        municipality: Municipality.first,
        author: @user,
        created_at: 20.days.ago
      )
    end

    visit new_issues_draft_path
    assert_current_path please_wait_profile_path
    assert_text "Dosiahli ste limit pre túto funkciu!"

    visit new_question_issues_drafts_path
    assert_current_path please_wait_profile_path
    assert_text "Dosiahli ste limit pre túto funkciu!"

    visit new_praise_path
    assert_current_path please_wait_profile_path
    assert_text "Dosiahli ste limit pre túto funkciu!"
  end

  test "user is redirected when exceeding issue update limit" do
    5.times do |i|
      update = Issues::Update.new(
        text: "Update #{i}",
        author: @user,
        created_at: 12.hours.ago,
        legacy_id: i # so we don't need to upload a photo
      )
      update.build_activity(issue: issues(:two), type: Issues::UpdateActivity)
      update.save!
    end

    visit issue_path(issues(:two))
    click_link "Aktualizovať podnet"

    # Should be redirected to please wait page
    assert_current_path please_wait_profile_path
    assert_text "Dosiahli ste limit pre túto funkciu!"
  end
end
