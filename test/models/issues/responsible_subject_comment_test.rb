require "test_helper"

class Issues::ResponsibleSubjectCommentTest < ActiveSupport::TestCase
  test "author_display_name returns subject_name for responsible subject not user name" do
    comment = Issues::ResponsibleSubjectComment.new
    comment.responsible_subject_author = ResponsibleSubject.new(subject_name: "Subject Display Name", name: "Regular Name")

    assert_equal "Subject Display Name", comment.author_display_name
  end

  test "activity bodies do not include the legacy portal tag" do
    comment = Issues::ResponsibleSubjectComment.new(text: "Public comment")

    assert_equal "Public comment", comment.triage_activity_body
    assert_equal "Public comment", comment.backoffice_activity_body
  end
end
