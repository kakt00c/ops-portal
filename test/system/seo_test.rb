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

  test "municipality issue list has its own title and canonical without other filters" do
    municipality = issues(:two).municipality
    visit issues_path(obec: municipality.name, page: 2, tab: "map")

    assert_equal "Podnety v obci #{municipality.name} | Odkaz pre starostu", page.title
    assert_selector "h1", text: "Nahlásené dopyty – #{municipality.name}"
    assert_selector "link[rel=canonical][href$='#{issues_path(obec: municipality.name)}']", visible: :all
  end

  test "unfiltered issue list is canonical to itself" do
    visit issues_path(page: 2)

    assert_equal "Nahlásené dopyty | Odkaz pre starostu", page.title
    assert_selector "link[rel=canonical][href$='#{issues_path}']", visible: :all
  end

  test "login page is not indexed" do
    visit "/login"

    assert_selector "meta[name=robots][content='noindex, follow']", visible: :all
  end
end
