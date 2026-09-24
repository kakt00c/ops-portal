require "test_helper"

class IssueTest < ActiveSupport::TestCase
  test "is invalid without a municipality" do
    issue = issues(:two).dup
    issue.municipality = nil
    assert_not issue.valid?
    assert_includes issue.errors[:municipality], "musí existovať"
  end

  test "is valid with a municipality" do
    issue = issues(:two).dup
    issue.triage_external_id = nil
    assert issue.valid?
  end
end
