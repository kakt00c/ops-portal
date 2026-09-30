require "test_helper"

class Legacy::WidgetsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect root with widget param to legacy widget endpoint" do
    get "/?widget=banska-bystrica&width=500"

    assert_redirected_to "/legacy/widget?widget=banska-bystrica&width=500"
  end

  test "should display widget at /widget endpoint" do
    get "/legacy/widget"

    assert_response :success
    assert_select "#wrapper"
    assert_select "#widget_podnety"
    assert_select "body", text: /wide/, count: 0
  end

  test "should display widget with legacy widget parameter format" do
    get "/legacy/widget?widget=trencin"

    assert_response :success
    assert_select "#wrapper"
  end

  test "should parse municipality and district from widget parameter" do
    get "/legacy/widget?widget=trencin/zilina-centrum"

    assert_response :success
    assert_select "#wrapper"
  end

  test "should display wide widget when width > 250" do
    get "/legacy/widget?width=300"

    assert_response :success
    assert_select "body.wide"
    assert_select "#widget_statistiky"
    assert_select "#header ul li", count: 2
  end

  test "should apply grey theme" do
    get "/legacy/widget?theme=grey"

    assert_response :success
    assert_select "body.grey"
  end

  test "should apply stavebna_policia theme" do
    get "/legacy/widget?theme=stavebna_policia"

    assert_response :success
    assert_select "body.stavebnapolicia"
  end

  test "should apply custom background color" do
    get "/legacy/widget?bg=FF0000"

    assert_response :success
    assert_select "style", text: /FF0000/
  end

  test "should filter by status" do
    state = issues_states(:in_progress)

    get "/legacy/widget?status=#{state.id}"

    assert_response :success
  end

  test "should limit results" do
    get "/legacy/widget?limit=5"

    assert_response :success
  end

  test "should display feed items when municipality has issues" do
    municipality = municipalities(:trencin)

    # Create some issues for this municipality with a publicly visible state
    state = Issues::State.find_by(key: "in_progress") || issues_states(:in_progress)
    category = Issues::Category.first || issues_categories(:one)
    Issue.create!(
      photos: [ active_storage_blobs(:issue_photo) ],
      title: "Test Issue 1",
      description: "Test description with enough characters to pass validation",
      municipality: municipality,
      state: state,
      category: category,
      author: users(:one),
      created_at: 1.day.ago
    )

    get "/legacy/widget?widget=trencin&width=300"

    assert_response :success
    assert_select ".podnet"
  end

  test "should not display private state issues in feed" do
    municipality = municipalities(:trencin)
    private_state = Issues::State.find_by(key: "resolved_private") || issues_states(:resolved_private)
    category = Issues::Category.first || issues_categories(:one)

    Issue.create!(
      photos: [ active_storage_blobs(:issue_photo) ],
      title: "Private Resolved Issue",
      description: "This is a private resolved issue with enough text to be valid",
      municipality: municipality,
      state: private_state,
      category: category,
      author: users(:one),
      created_at: 1.day.ago
    )

    get "/legacy/widget?widget=trencin"

    assert_response :success
    # Should not show the private issue title
    assert_select ".podnet h2 a", text: "Private Resolved Issue", count: 0
  end

  test "should calculate statistics when width > 250" do
    municipality = municipalities(:trencin)
    state = Issues::State.find_by(key: "in_progress") || issues_states(:in_progress)
    category = Issues::Category.first || issues_categories(:one)

    # Create multiple issues for statistics
    3.times do |i|
      Issue.create!(
        photos: [ active_storage_blobs(:issue_photo) ],
        title: "Statistic Issue #{i}",
        description: "Test description with enough characters to pass validation requirements",
        municipality: municipality,
        state: state,
        category: category,
        author: users(:one),
        created_at: i.days.ago,
        updated_at: i.days.ago
      )
    end

    get "/legacy/widget?widget=trencin&width=300"

    assert_response :success
    assert_select "#widget_statistiky"
    # Check that statistics are displayed with numbers
    assert_select "#widget_statistiky h1 b", text: /\d+/
  end

  test "should handle invalid municipality gracefully" do
    get "/legacy/widget?widget=nonexistent-city"

    assert_response :success
    # Should still render the widget even without municipality
    assert_select "#wrapper"
  end

  test "should respect maximum limit of 16 items" do
    municipality = municipalities(:trencin)
    state = Issues::State.find_by(key: "in_progress") || issues_states(:in_progress)
    category = Issues::Category.first || issues_categories(:one)

    # Create many issues
    20.times do |i|
      Issue.create!(
        photos: [ active_storage_blobs(:issue_photo) ],
        title: "Limit Test Issue #{i}",
        description: "Test description with enough characters to be valid and pass all requirements",
        municipality: municipality,
        state: state,
        category: category,
        author: users(:one),
        created_at: i.hours.ago
      )
    end

    get "/legacy/widget?widget=trencin&limit=20"

    assert_response :success
    # Should limit to 16 items
    podnets = css_select(".podnet")
    assert_operator podnets.count, :<=, 16
  end

  test "should allow iframe embedding with X-Frame-Options set to ALLOWALL" do
    get "/legacy/widget"

    assert_response :success
    assert_equal "ALLOWALL", response.headers["X-Frame-Options"]
  end

  test "should set Content-Security-Policy for iframe embedding" do
    get "/legacy/widget"

    assert_response :success
    assert_match /frame-ancestors/, response.headers["Content-Security-Policy"]
  end
end
