require "test_helper"

# One-click unsubscribe (RFC 8058): mail clients POST to the List-Unsubscribe URL without a session.
class GlobalSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "one-click unsubscribe turns off email notifications" do
    user = users(:two)

    post unsubscribe_global_subscriptions_path(token: user.email_global_unsubscribe_token), params: { "List-Unsubscribe" => "One-Click" }

    assert_response :ok
    assert_not user.reload.email_notifiable?
  end

  test "one-click unsubscribe with unknown token is not found" do
    post unsubscribe_global_subscriptions_path(token: "nonsense")

    assert_response :not_found
  end
end
