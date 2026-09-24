require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  test "creating an account with email verification" do
    visit "/create-account"
    assert_selector "h1", text: "Vytvoriť účet"

    click_button "Vytvoriť účet"

    assert_selector ".flash-message-container", text: "Pri vytváraní účtu nastala chyba."

    fill_in "Email", with: "new-account@example.com"
    fill_in "Heslo", with: "Very_secret_123", match: :first
    fill_in "Heslo (znova)", with: "Very_secret_123"

    fill_in "Meno", with: "Jozef"

    click_button "Vytvoriť účet"

    assert_selector ".flash-message-container", text: "Zaslali sme Vám email odkazom na overenie účtu"

    verify_account
  end

  test "creating an account via Google SSO" do
    email = "google-user-#{SecureRandom.hex(4)}@example.com"
    original_test_mode = OmniAuth.config.test_mode
    original_mock_auth = OmniAuth.config.mock_auth.dup

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new(
      "provider" => "google",
      "uid" => "google-uid-#{SecureRandom.hex(4)}",
      "info" => {
        "email" => email,
        "name" => "Google User",
        "first_name" => "Google",
        "last_name" => "User"
      }
    )

    visit "/create-account"

    assert_no_enqueued_emails do
      click_button "Vytvoriť účet cez Google"
    end

    assert_selector "a.login", text: "Google User"
    assert_selector "h1", text: "Vitajte na portáli Odkaz pre starostu!"
    assert_equal "true", find("input[name='user[onboarded]']", visible: false).value

    user = User.find_by!(email: email)
    assert user.verified?
    refute user.onboarded?

    check "user_terms_of_service"
    click_button "Uložiť"

    assert_current_path root_path
  ensure
    OmniAuth.config.test_mode = original_test_mode
    OmniAuth.config.mock_auth = original_mock_auth
  end

  test "login" do
    user = users(:one)

    visit root_path

    assert_selector "a.login", text: "Prihlásiť"

    login(user.email, "password")

    assert_selector "a.login", text: user.firstname
  end

  test "logout" do
    login(users(:one).email, "password")

    logout

    assert_selector "a.login", text: "Prihlásiť"
  end

  test "banned user cannot login" do
    user = users(:one)
    user.update!(banned: true)

    visit "/login"

    fill_in "Email", with: user.email
    fill_in "Heslo", with: "password"

    click_button "Prihlásiť"

    assert_selector ".flash-message-container", text: "Váš účet bol zablokovaný."
    assert_selector "a.login", text: "Prihlásiť"
  end

  test "banned user gets logged out if already logged in" do
    user = users(:one)

    login(user.email, "password")
    assert_selector "a.login", text: user.firstname

    user.update!(banned: true)

    visit root_path

    assert_selector ".flash-message-container", text: "Váš účet bol zablokovaný."
    assert_selector "a.login", text: "Prihlásiť"
  end

  test "citizen user can login via email (magic link)" do
    user = users(:one)

    visit root_path

    assert_selector "a.login", text: "Prihlásiť"

    login_via_magic_link(user.email)

    assert_selector "a.login", text: user.firstname
  end

  test "login via email with invalid link" do
    user = users(:one)

    visit "/login"
    click_on "Prihlásiť sa cez email"

    assert_selector "h1", text: "Prihlásenie bez hesla"

    fill_in "Email", with: user.email
    click_on "Poslať prihlasovací odkaz"

    assert_text "Email s prihlasovacím odkazom bol odoslaný."

    visit "/email-auth?key=invalid_key"

    assert_text "Neplatný prihlasovací odkaz."
    assert_selector "h1", text: "Prihlásenie"
  end

  test "responsible subject user cannot login via password" do
    user = users(:responsible_subject)

    visit "/login"
    fill_in "Email", with: user.email
    fill_in "Heslo", with: "password"
    click_button "Prihlásiť"

    assert_text "Pre tento účet je povolené prihlásenie iba cez email."
    assert_selector "a.login", text: "Prihlásiť"
  end

  test "responsible subject user can login via email (magic link)" do
    user = users(:responsible_subject)

    visit root_path

    assert_selector "a.login", text: "Prihlásiť"

    login_via_magic_link(user.email)

    assert_selector "a.login", text: user.firstname
  end

  private

  def verify_account
    perform_enqueued_jobs # run enqueued email deliveries
    email = ActionMailer::Base.deliveries.last

    verify_account_path = email.body.to_s.match(/(\/verify-account\S+)"/).captures[0]

    visit verify_account_path

    click_on "Potvrdiť registráciu"
  end
end
