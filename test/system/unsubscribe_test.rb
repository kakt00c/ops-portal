require "application_system_test_case"

class UnsubscribeTest < ApplicationSystemTestCase
  test "unsubscribe from one issue via email link" do
    subscription = issue_subscriptions(:one_two)

    visit unsubscribe_subscriptions_path(token: subscription.email_unsubscribe_token)

    assert_current_path root_path
    assert_text "Odhlásenie z odberu bolo úspešné."
    assert_nil IssueSubscription.find_by(id: subscription.id)
    assert users(:two).reload.email_notifiable?
  end

  test "unsubscribe from all notifications via email link" do
    user = users(:two)

    visit unsubscribe_global_subscriptions_path(token: user.email_global_unsubscribe_token)

    assert_current_path root_path
    assert_text "Odhlásenie z odberu bolo úspešné."
    assert_not user.reload.email_notifiable?
    assert_equal 1, user.issue_subscriptions.where(issue: issues(:one)).count
  end

  test "invalid unsubscribe links show an error" do
    visit unsubscribe_subscriptions_path(token: "nonsense")
    assert_text "Odhlásenie z odberu sa nepodarilo"

    visit unsubscribe_global_subscriptions_path(token: "nonsense")
    assert_text "Odhlásenie z odberu sa nepodarilo"
  end
end
