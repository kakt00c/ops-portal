require "application_system_test_case"

class IssueSubscriptionsTest < ApplicationSystemTestCase
  test "logged in user can follow and unfollow an issue" do
    issue = issues(:legacy_discussion_closed)
    user = users(:legacy_citizen)
    login_as user
    visit issue_path(issue)

    click_on "Sledovať podnet"
    assert_text "Zrušiť sledovanie"
    assert user.subscribed_to?(issue)

    visit watched_issues_profile_path
    assert_text issue.title

    visit issue_path(issue)
    click_on "Zrušiť sledovanie"
    assert_text "Sledovať podnet"
    assert_not user.reload.subscribed_to?(issue)
  end

  test "anonymous user is asked to create a profile" do
    visit issue_path(issues(:two))

    click_on "Sledovať podnet"

    assert_current_path please_create_profile_path
  end
end
