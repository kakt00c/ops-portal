require "application_system_test_case"

class ProfilesTest < ApplicationSystemTestCase
  test "citizen user can update profile name and birth year" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    assert_selector "h1", text: "Osobné údaje"

    fill_in "Meno*", with: "Updated Citizen Name"
    fill_in "Rok narodenia", with: "1990"

    # Set anonymous mode (choosing 'Nie' means anonymous = true)
    choose "user_anonymous_true"

    # Select municipality
    select "Nitra", from: "municipality_id"

    # Set email notifications
    choose "user_email_notifiable_true"

    # Check newsletter
    check "user_newsletter_accepted"

    # Check GDPR stats
    check "user_gdpr_stats_accepted"

    within('form[action="/profil"]') do
      click_button "Uložiť"
    end

    assert_text "Zmeny profilu boli uložené."

    user.reload
    assert_equal "Updated Citizen Name", user.name
    assert_equal 1990, user.birth_year
    assert_equal true, user.anonymous
    assert_equal Municipality.find_by(name: "Nitra").id, user.municipality_id
    assert_equal true, user.email_notifiable
    assert_equal true, user.newsletter_accepted
    assert_equal true, user.gdpr_stats_accepted
  end

  test "responsible subject user can't update profile" do
    user = users(:responsible_subject)
    login_via_magic_link(user.email)

    visit edit_profile_path

    assert_text "Túto akciu nemôžete vykonať."
  end

  test "citizen user requires login to access profile edit" do
    visit edit_profile_path

    # Should redirect to login
    assert_text "a byť prihlásený"
  end

  test "citizen user can change profile picture" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    assert_selector "h1", text: "Osobné údaje"

    # Verify user doesn't have an avatar initially
    assert_not user.avatar.attached?

    # Attach a test image via the hidden file field (triggered by "Zmeniť fotku" button)
    page.attach_file("user[avatar]", Rails.root.join("test/fixtures/files/avatar.png"), make_visible: true)

    # Wait for auto-submit to complete
    sleep 1

    # Verify the avatar was attached
    user.reload
    assert user.avatar.attached?
    assert_equal "avatar.png", user.avatar.filename.to_s
  end

  test "citizen user sees an error when the new profile picture is not an image" do
    user = users(:one)
    login_as(user)

    visit edit_profile_path
    assert_selector "h1", text: "Osobné údaje"
    assert_selector "input[name='user[avatar]'][accept='image/*']", visible: :all

    page.attach_file("user[avatar]", file_fixture("responsible_subject_emails/ivanka_expected.txt"), make_visible: true)

    assert_text "Profilová fotka môže byť iba obrázok."
    assert_not user.reload.avatar.attached?
  end
end
