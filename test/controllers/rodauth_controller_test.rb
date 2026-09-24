require "test_helper"

class RodauthControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "create account creates citizen" do
    email = "user-#{SecureRandom.hex(4)}@example.com"

    assert_enqueued_emails 1 do
      assert_difference("User.count", 1) do
        post "/create-account", params: {
          email: email,
          password: "Very_secret_123",
          "password-confirm": "Very_secret_123",
          name: "new-user-#{SecureRandom.hex(4)}"
        }
      end
    end

    assert_response :redirect

    user = User.find_by!(email: email)
    assert_equal "User::Citizen", user.type
    assert user.unverified?
    assert user.email_global_unsubscribe_token.present?
  end

  test "Google SSO creates a citizen with the Google profile name" do
    email = "google-user-#{SecureRandom.hex(4)}@example.com"
    uid = "google-uid-#{SecureRandom.hex(4)}"
    original_test_mode = OmniAuth.config.test_mode
    original_mock_auth = OmniAuth.config.mock_auth.dup

    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new(
      "provider" => "google",
      "uid" => uid,
      "info" => {
        "email" => email,
        "name" => "Google User",
        "first_name" => "Google",
        "last_name" => "User"
      }
    )

    assert_difference("User.count", 1) do
      get "/auth/google/callback"
    end

    assert_response :redirect

    user = User.find_by!(email: email)
    assert_equal "User::Citizen", user.type
    assert_equal "Google", user.firstname
    assert_equal "User", user.lastname
    assert_equal "Google User", user.name
    assert user.verified?
    refute user.onboarded?
    assert user.email_global_unsubscribe_token.present?

    identity = ActiveRecord::Base.connection.select_one(<<~SQL)
      SELECT provider, uid
      FROM user_identities
      WHERE user_id = #{user.id}
    SQL
    assert_equal({ "provider" => "google", "uid" => uid }, identity)
  ensure
    OmniAuth.config.test_mode = original_test_mode
    OmniAuth.config.mock_auth = original_mock_auth
  end
end
