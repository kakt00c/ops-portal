require "test_helper"

class PgSearch::FasterTest < ActiveSupport::TestCase
  test "fulltext_search handles apostrophes without error" do
    # Toto pred opravou spôsobilo PG::SyntaxError
    assert_nothing_raised do
      Issue.fulltext_search("ivanka pri dunaji'123", against: [ :title ])
    end
  end

  test "fulltext_search sanitizes all disallowed tsquery characters" do
    assert_nothing_raised do
      Issue.fulltext_search("test'?\\:query", against: [ :title ])
    end
  end

  test "fulltext_search returns empty result for only special characters" do
    issue = issues(:two)

    result = Issue.fulltext_search("'''???", against: [ :title ])
    assert_empty result
  end

  test "fulltext_search still works for normal queries" do
    issue = issues(:two)

    result = Issue.fulltext_search("Bratislava", against: [ :title ])
    assert_includes result, issue
  end

  test "sanitize_terms removes apostrophes and splits correctly" do
    result = Issue.sanitize_terms("ivanka pri dunaji'123")
    assert_equal [ "ivanka", "pri", "dunaji", "123" ], result
  end

  test "sanitize_terms removes all disallowed characters and splits correctly" do
    result = Issue.sanitize_terms("test'?\\:query")
    assert_equal [ "test", "query" ], result
  end

  test "sanitize_terms returns empty array for only special characters" do
    result = Issue.sanitize_terms("'''???")
    assert_empty result
  end

  test "sanitize_terms handles normal queries" do
    result = Issue.sanitize_terms("Bratislava hlavne mesto")
    assert_equal [ "Bratislava", "hlavne", "mesto" ], result
  end

  test "sanitize_terms handles mixed input" do
    result = Issue.sanitize_terms("test'normal\\:mixed?query")
    assert_equal [ "test", "normal", "mixed", "query" ], result
  end
end
