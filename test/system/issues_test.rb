require "application_system_test_case"

class IssuesTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit issues_path
    assert_selector "h1", text: "Nahlásené dopyty"

    within ".podnety-con" do
      assert_text "Legacy issue"
      assert_text "Issue from Bratislava"
      assert_text "Finally cleaned"
    end
  end

  test "published praise" do
    visit issue_path(issues(:praise_published))

    assert_selector "h1", text: "Finally cleaned"
    assert_text "Very good job cleaning the park, thank you!"
  end
end
