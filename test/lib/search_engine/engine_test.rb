require "test_helper"

class SearchEngine::EngineTest < ActiveSupport::TestCase
  test "hits are paginated by the page param" do
    engine = SearchEngine.new(filters: [], per_page: 1)

    results = engine.search(Issue.order(:id), { page: "2" })

    assert_equal [ Issue.order(:id).second ], results.hits.to_a
  end
end
