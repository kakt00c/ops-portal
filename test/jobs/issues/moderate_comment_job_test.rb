require "test_helper"
require "test_helpers/request_helper"

class Issues::ModerateCommentJobTest < ActiveJob::TestCase
  include RequestHelper

  setup do
    @comment = issues_comments(:one_comment1)

    @comment.update!(hidden: false, ai_evaluation: {})

    @gemini_url = /generativelanguage\.googleapis\.com\/v1beta\/models\/gemini.*:generateContent/
  end

  teardown do
    WebMock.reset!
  end

  test "hides comment and saves evaluation when score is above threshold" do
    stub_json_request(
      :post,
      @gemini_url,
      response: "webmock/gemini/moderate-comment-toxic.json"
    )

    Issues::ModerateCommentJob.perform_now(@comment)

    @comment.reload
    assert @comment.hidden?, "Comment should be hidden because score is >= 0.9"
    assert_equal 0.92, @comment.ai_evaluation["overall_score"]
  end

  test "keeps comment visible and saves evaluation when score is below threshold" do
    stub_json_request(
      :post,
      @gemini_url,
      response: "webmock/gemini/moderate-comment-ok.json"
    )

    Issues::ModerateCommentJob.perform_now(@comment)

    @comment.reload
    assert_not @comment.hidden?, "Comment should NOT be hidden because score is < 0.9"
    assert_equal 0.1, @comment.ai_evaluation["overall_score"]
  end

  test "does not hide comment if Gemini fails or returns invalid response" do
    stub_request(:post, @gemini_url).to_return(status: 500)

    assert_nothing_raised do
      Issues::ModerateCommentJob.perform_now(@comment)
    end

    @comment.reload
    assert_not @comment.hidden?
    assert_nil @comment.ai_evaluation
  end
end
