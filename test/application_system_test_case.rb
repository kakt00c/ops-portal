require "test_helper"
require "test_helpers/auth_helper"
require "capybara"

Capybara.register_driver :selenium_chrome_no_password_warning do |app|
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: Selenium::WebDriver::Options.chrome.tap do |options|
      # Other options removed for clarity
      options.add_preference("profile.password_manager_leak_detection", false)

      options.add_argument("--disable-search-engine-choice-screen")
      options.add_argument("--headless") # comment this line if you want to see the browser
      options.add_argument("--disable-gpu") if Gem.win_platform?
      options.add_argument("--window-size=1400,1400") # has to be set like this, GitHub CI has some own custom
    end
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium_chrome_no_password_warning

  include ActiveJob::TestHelper
  include AuthHelper
  include MunicipalityBoundaryTestHelper

  teardown do
    Capybara.reset_sessions!
    ActiveRecord::Base.connection.execute("DELETE FROM user_remember_keys")
  end

  def click_on(locator, **options)
    element = find(:link_or_button, locator, **options)
    scroll_to(element)

    begin
      element.click
    rescue Selenium::WebDriver::Error::ElementClickInterceptedError
      page.execute_script("arguments[0].click();", element.native)
    end
  end

  alias_method :click_link_or_button, :click_on

  private

  def scroll_to(element)
    script = "arguments[0].scrollIntoView({block: 'center', behavior: 'instant'});"
    page.execute_script(script, element.native)
    sleep 0.2 # Small delay to ensure scroll completes and page settles
  end
end
