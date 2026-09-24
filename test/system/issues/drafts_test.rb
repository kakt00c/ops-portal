require "application_system_test_case"
require "test_helpers/issues/drafts_helper"

class Issues::DraftsTest < ApplicationSystemTestCase
  include Issues::DraftsHelper

  setup do
    @user = users(:one)

    stub_json_request(
      :post,
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=",
      body: /checks prompt/,
      response: "webmock/gemini/checks-confirmable.json"
    )

    stub_json_request(
      :post,
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=",
      body: /suggestions prompt/,
      response: "webmock/gemini/suggestions-graffiti.json"
    )

    stub_json_request(
      :get,
      "https://nominatim.openstreetmap.org/reverse?format=json&lat=48.16311388888889&lon=17.049330555555557",
      response: "webmock/nominatim/pusta-reverse.json"
    )

    stub_json_request(
      :get,
      "https://nominatim.openstreetmap.org/details?addressdetails=1&format=json&osmid=25298061&osmtype=W",
      response: "webmock/nominatim/pusta-details.json"
    )
  end

  teardown do
    WebMock.reset!
  end

  test "full issue creation with checks" do
    # Create boundaries for the test location (Bratislava, ~48.1631, 17.0493)
    bratislava = municipalities("bratislava")
    karlova_ves = municipality_districts("Karlova Ves")
    create_municipality_boundary(municipality: bratislava, center_lat: 48.1631, center_lon: 17.0493, size: 0.5)
    create_municipality_boundary(municipality: bratislava, district: karlova_ves, center_lat: 48.1631, center_lon: 17.0493, size: 0.1)

    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Poškodená rozvodná skriňa"
    assert_text "Popis podnetu"

    click_on "Vlastný nadpis podnetu"

    assert_text "Výber kategórie problému"
    click_on "Zeleň a životné prostredie"

    assert_text "Výber podkategórie problému"
    click_on "Strom"

    assert_text "Výber typu problému"
    click_on "vyvaleny"

    assert_text "Popis podnetu"
    fill_in "Názov", with: "Graffiti na skrini"
    fill_in "Popis", with: "Je tu graffiti, treba vycistit"
    click_on "Pokračovať"

    assert_text "Zhrnutie podnetu"
    click_on "Odoslať podnet"

    assert_text "Podnet má problém"
    click_on "Odoslať podnet aj tak"

    assert_text "Podnet bol odoslaný!"

    click_on "Zobraziť všetky moje podnety"
    assert_text "Graffiti"

    click_on "Sledované podnety"
    assert_text "Legacy issue"
    assert_text "Graffiti"
  end

  test "issue creation on unsupported municipality" do
    municipality = municipalities("bratislava")
    municipality.update!(active: false)

    # Create only municipality boundary (no district), so point matches inactive municipality
    create_municipality_boundary(municipality: municipality, center_lat: 48.1631, center_lon: 17.0493, size: 0.5)

    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Poškodená rozvodná skriňa"
    assert_text "Popis podnetu"

    click_on "Vlastný nadpis podnetu"

    assert_text "Samospráva nie je zatiaľ zapojená do portálu Odkaz pre starostu"
  end

  test "issue creation on unsupported municipality district" do
    municipality = municipalities("bratislava")
    municipality_district = municipality_districts("Karlova Ves")
    municipality_district.update!(active: false)

    # Create district boundary so point matches inactive district
    create_municipality_boundary(municipality: municipality, district: municipality_district, center_lat: 48.1631, center_lon: 17.0493, size: 0.1)

    login_as(@user)

    click_on "Nahlásiť podnet"

    attach_file "issues_draft_photos", "test/fixtures/files/graffiti-with-geo.jpg", visible: false

    assert_text "Lokalita"
    click_on "Pokračovať"

    assert_text "Poškodená rozvodná skriňa"
    assert_text "Popis podnetu"

    click_on "Vlastný nadpis podnetu"

    assert_text "Mestská časť nie je zatiaľ zapojená do portálu Odkaz pre starostu"
  end
end
