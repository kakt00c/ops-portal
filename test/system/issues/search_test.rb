require "application_system_test_case"

class Issues::SearchTest < ApplicationSystemTestCase
  setup do
    @bratislava = issues(:two)          # Bratislava, in progress, category one
    @nitra = issues(:sent_to_responsible)
    @nitra.update_columns(municipality_id: municipalities(:Nitra).id, responsible_subject_id: responsible_subjects(:two).id, state_id: issues_states(:referred).id)
    @private = issues(:resolved_private)
  end

  test "list shows publicly visible issues only" do
    visit issues_path

    assert_text @bratislava.title
    assert_text @nitra.title
    assert_no_text @private.title
    assert_no_text issues(:one).title # waiting
  end

  test "filter by municipality" do
    visit issues_path(obec: "Nitra")

    assert_text @nitra.title
    assert_no_text @bratislava.title
  end

  test "filter by responsible subject and by state" do
    visit issues_path(zodpovedny: "BVS")
    assert_text @nitra.title
    assert_no_text @bratislava.title

    visit issues_path(stav: "Odstúpený")
    assert_text @nitra.title
    assert_no_text @bratislava.title
  end

  test "filter by type of request" do
    visit issues_path(dopyt: "Pochvala")

    assert_text issues(:praise_published).title
    assert_no_text @bratislava.title
  end

  test "fulltext search and search by ticket number" do
    visit issues_path(q: "Bratislava")
    assert_text @bratislava.title
    assert_no_text @nitra.title

    visit issues_path(q: "Ticket#R-#{@nitra.id}")
    assert_text @nitra.title
    assert_no_text @bratislava.title
  end

  test "logged in user can narrow the list to own and to followed issues" do
    user = users(:legacy_citizen)
    @bratislava.update_columns(author_id: user.id)
    user.subscribe_to(issues(:legacy1))
    login_as user

    visit issues_path(zobrazit: "Moje dopyty")
    assert_text @bratislava.title
    assert_no_text issues(:legacy1).title

    visit issues_path(zobrazit: "Sledované dopyty")
    assert_text issues(:legacy1).title
    assert_no_text @bratislava.title
  end

  test "sorting by popularity puts the most liked issue first" do
    @nitra.update_columns(likes_count: 5)

    visit issues_path(sort: "oblubene")

    assert_operator page.text.index(@nitra.title), :<, page.text.index(@bratislava.title)
  end

  test "stats tab shows counts" do
    visit issues_path(tab: "stats")

    assert_text "V riešení"
    assert_text "Odstúpený"
  end
end
