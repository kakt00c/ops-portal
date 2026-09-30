require "test_helper"

class Legacy::RedirectsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect legacy login to new login" do
    get "/r/login"

    assert_redirected_to "/login"
  end

  test "should redirect legacy global all issues list to issues path" do
    get "/r/vsetky-podnety"

    assert_redirected_to issues_path
  end

  test "should redirect legacy user URL to user page" do
    citizen = users(:legacy_citizen)

    get "/r/ludia/#{citizen.legacy_id}"

    assert_redirected_to user_path(citizen)
  end

  test "should return 404 when user with legacy_id not found" do
    get "/r/ludia/99999"

    assert_response :not_found
  end

  test "should redirect legacy municipality root to new root" do
    get "/r/bratislava"

    assert_redirected_to root_path
  end

  test "should redirect legacy all issues list to municipality issues path" do
    get "/r/bratislava/vsetky-podnety"

    assert_redirected_to issues_path(obec: "Bratislava")
  end

  test "should redirect legacy all issues list of non-existent municipality to issues path" do
    get "/r/non-existent/vsetky-podnety"

    assert_redirected_to issues_path
  end

  test "should redirect legacy municipality district issues list to municipality district issues path" do
    get "/r/bratislava/podnety/stare-mesto"

    assert_redirected_to issues_path(obec: "Bratislava", cast: "Staré Mesto")
  end

  test "should redirect legacy municipality district issues list to municipality issues path when district does not exist" do
    get "/r/bratislava/podnety/neexistujuca-stvrt"

    assert_redirected_to issues_path(obec: "Bratislava")
  end

  test "should redirect legacy municipality district issues list of non-existent municipality to issues path" do
    get "/r/non-existent/podnety/stare-mesto"

    assert_redirected_to issues_path
  end

  test "should redirect legacy street index to municipality issues path" do
    get "/r/trencin/podnety/ulica"

    assert_redirected_to issues_path(obec: "Trenčín")
  end

  test "should redirect legacy street slug to municipality issues path with street" do
    get "/r/trencin/podnety/ulica/1480/viedenska-cesta-stara-cast"

    assert_redirected_to issues_path(obec: "Trenčín", ulica: "Viedenská cesta")
  end

  test "should redirect legacy street slug with known status to municipality issues path with street and state" do
    get "/r/trencin/podnety/ulica/1480/viedenska-cesta-stara-cast?status=2"

    assert_redirected_to issues_path(obec: "Trenčín", ulica: "Viedenská cesta", stav: "V riešení")
  end

  test "should redirect legacy street slug with unknown status to municipality issues path with street only" do
    get "/r/trencin/podnety/ulica/1480/viedenska-cesta-stara-cast?status=999"

    assert_redirected_to issues_path(obec: "Trenčín", ulica: "Viedenská cesta")
  end

  test "should redirect legacy street slug of non-existent municipality to issues path" do
    get "/r/non-existent/podnety/ulica/1480/viedenska-cesta-stara-cast"

    assert_redirected_to issues_path
  end

  test "should return 404 when street with legacy_id not found" do
    get "/r/trencin/podnety/ulica/99999/any-slug"

    assert_response :not_found
  end

  test "should redirect legacy statistics page to municipality issues stats tab" do
    get "/r/bratislava/statistiky"

    assert_redirected_to issues_path(obec: "Bratislava", tab: "stats")
  end

  test "should redirect legacy statistics page of non-existent municipality to issues path" do
    get "/r/non-existent/statistiky"

    assert_redirected_to issues_path
  end

  test "should redirect legacy map page to municipality issues map tab" do
    get "/r/bratislava/mapa"

    assert_redirected_to issues_path(obec: "Bratislava", tab: "map")
  end

  test "should redirect legacy map page of non-existent municipality to issues path" do
    get "/r/non-existent/mapa"

    assert_redirected_to issues_path
  end

  test "should redirect legacy municipality news list to news" do
    get "/r/bratislava/vsetky-aktuality"

    assert_redirected_to "/aktuality"
  end

  test "should redirect legacy issue page to new issue page" do
    get "/r/bratislava/podnety/12345/any-slug"

    assert_redirected_to issue_path(issues(:legacy1))
  end

  test "should redirect legacy issue page with query params to new issue page" do
    get "/r/bratislava/podnety/12345/any-slug?utm_source=legacy"

    assert_redirected_to issue_path(issues(:legacy1))
  end

  test "should redirect legacy issue update page to new issue page" do
    get "/r/bratislava/podnety/12345/any-slug/aktualizovat-podnet"

    assert_redirected_to issue_path(issues(:legacy1))
  end

  test "should return 404 when issue with legacy_id not found" do
    get "/r/bratislava/podnety/99999/any-slug"

    assert_response :not_found
  end

  test "should redirect legacy issue creation page to welcome page" do
    get "/r/bratislava/pridat-podnet"

    assert_redirected_to cms_page_path("vitajte-na-novom-portali-odkaz-pre-starostu")
  end

  test "should set legacy visit cookie when visiting legacy routes" do
    get "/r/bratislava"

    assert_equal "1", cookies[:legacy_visit]
  end
end
