require "application_system_test_case"

class IssueLikesTest < ApplicationSystemTestCase
  test "verified user can like and unlike an issue" do
    issue = issues(:two)
    login_as users(:one)
    visit issue_path(issue)

    within ".share-buttons" do
      assert_selector ".button-like:not(.button-active)", text: "0"
      find(".button-like").click
      assert_selector ".button-like.button-active", text: "1"
    end
    assert_equal 1, issue.reload.likes_count
    assert issue.liked_by?(users(:one))

    within ".share-buttons" do
      find(".button-like").click
      assert_selector ".button-like:not(.button-active)", text: "0"
    end
    assert_equal 0, issue.reload.likes_count
  end

  test "anonymous user is asked to create a profile" do
    visit issue_path(issues(:two))

    find(".share-buttons .button-like").click

    assert_current_path please_create_profile_path
    assert_equal 0, issues(:two).reload.likes_count
  end
end
