require "application_system_test_case"

class SeoTest < ApplicationSystemTestCase
  test "issue page has location in title and its own meta tags" do
    issue = issues(:two)
    visit issue_path(issue)

    assert_equal "#{issue.title} – #{issue.municipality.name} | Odkaz pre starostu", page.title
    assert_selector "html[lang=sk]", visible: :all
    assert_selector "meta[name=description][content^='Hello, this is an issue']", visible: :all
    assert_selector "link[rel=canonical][href$='#{issue_path(issue)}']", visible: :all
    assert_selector "meta[property='og:type'][content=article]", visible: :all
    assert_no_selector "meta[name=robots]", visible: :all
  end

  test "home page has default description and is indexable" do
    visit root_path

    assert_equal "Odkaz pre starostu – nahláste podnet svojej obci", page.title
    assert_selector "meta[name=description]", visible: :all
    assert_selector "meta[property='og:type'][content=website]", visible: :all
    assert_no_selector "meta[name=robots]", visible: :all
  end

  test "login page is not indexed" do
    visit "/login"

    assert_selector "meta[name=robots][content='noindex, follow']", visible: :all
  end
end
