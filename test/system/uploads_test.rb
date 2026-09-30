require "application_system_test_case"

# The photo upload widget is shared by comments, updates and drafts; it is exercised here through the issue update form.
class UploadsTest < ApplicationSystemTestCase
  setup do
    login_as users(:one)
    visit issue_path(issues(:two))
    click_on "Aktualizovať podnet"
  end

  test "selected photo is uploaded and previewed" do
    attach_file "new_files[]", file_fixture("graffiti-with-geo.jpg").to_s, visible: false

    assert_selector "figure.small-picture img", count: 1
    assert_equal "graffiti-with-geo.jpg", ActiveStorage::Blob.last.filename.to_s
  end

  test "files that are not images are ignored" do
    attach_file "new_files[]", file_fixture("responsible_subject_emails/ivanka_expected.txt").to_s, visible: false

    assert_no_selector "figure.small-picture img", wait: 2
  end

  test "photo can be rotated before submitting" do
    attach_file "new_files[]", file_fixture("graffiti-with-geo.jpg").to_s, visible: false
    assert_selector "figure.small-picture img"

    # Blob.last is unreliable here: rendering the preview stores the processed variant as another blob
    blob = ActiveStorage::Blob.find_signed!(find("input[name='blobs[]']", visible: false).value)
    original_src = page.evaluate_script("document.querySelector('figure.small-picture img').getAttribute('src')")

    find("figure.small-picture .rotate-button").click

    # the rotated variant has a different URL, so its arrival proves the request finished
    assert_no_selector "figure.small-picture img[src='#{original_src}']"
    assert_equal 270, blob.reload.rotation
  end

  test "photo can be removed before submitting" do
    attach_file "new_files[]", file_fixture("graffiti-with-geo.jpg").to_s, visible: false
    assert_selector "figure.small-picture img"

    accept_confirm "Naozaj chcete odstrániť túto fotografiu?" do
      find("figure.small-picture .close-button").click
    end

    assert_no_selector "figure.small-picture"
    fill_in "issues_update_text", with: "Bez fotky"
    click_on "Odoslať"
    assert_text "Fotografia pri overovaní podnetu je povinná položka"
  end
end
