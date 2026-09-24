require "test_helper"

class Issues::Drafts::AnonymousAccessTest < ActionDispatch::IntegrationTest
  test "anonymous user is redirected to profile creation from all draft step routes" do
    draft_id = 123

    {
      "checks"      => issues_draft_checks_url(draft_id),
      "geo"         => issues_draft_geo_url(draft_id),
      "suggestions" => issues_draft_suggestions_url(draft_id),
      "summary"     => issues_draft_summary_url(draft_id),
      "details"     => issues_draft_details_url(draft_id),
      "category"    => issues_draft_category_url(draft_id),
      "subcategory" => issues_draft_subcategory_url(draft_id),
      "subtype"     => issues_draft_subtype_url(draft_id)
    }.each do |step, url|
      get url
      assert_redirected_to please_create_profile_path, "Expected #{step} to redirect anonymous user"
    end
  end
end
