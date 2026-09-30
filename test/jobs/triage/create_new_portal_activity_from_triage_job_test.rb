require "test_helper"
require "test_helpers/triage_helper"

class Triage::CreateNewPortalActivityFromTriageJobTest < ActiveJob::TestCase
  include TriageHelper

  ALLOWED = [ :agent_portal_comment, :agent_portal_and_backoffice_comment, :responsible_subject_portal_and_backoffice_comment, :agent_private_comment ]

  def perform(ticket, article, ticket_id:, article_id: 7)
    client = Minitest::Mock.new
    client.expect :get_ticket, ticket, [ ticket_id ]
    client.expect :get_article, article, [ ticket_id, article_id ], allowed_article_types: ALLOWED if ticket && ticket[:origin] == "portal"
    Triage::CreateNewPortalActivityFromTriageJob.new.perform(ticket_id, article_id, triage_zammad_client: client)
    assert_mock client
  end

  test "agent note on a triage ticket becomes a private agent comment with attachments" do
    issue = issues(:one)
    article = triage_article(article_type: :agent_private_comment, body: "Interná poznámka", attachments: [ triage_attachment ])

    perform triage_ticket(issue, process_type: "portal_issue_triage"), article, ticket_id: 1

    comment = issue.comments.last
    assert_kind_of Issues::AgentPrivateComment, comment
    assert_equal "Interná poznámka", comment.text
    assert_equal 7, comment.triage_external_id
    assert_equal [ "photo.jpg" ], comment.attachments.map { |a| a.filename.to_s }
  end

  test "responsible subject reply on a resolution ticket becomes a responsible subject comment" do
    issue = issues(:two)
    article = triage_article(article_type: :responsible_subject_portal_and_backoffice_comment, body: "Odpoveď mesta", author: responsible_subjects(:one))

    perform triage_ticket(issue), article, ticket_id: 3

    comment = issue.comments.last
    assert_kind_of Issues::ResponsibleSubjectComment, comment
    assert_equal responsible_subjects(:one), comment.responsible_subject_author
    assert_equal "Odpoveď mesta", comment.text
  end

  test "agent reply on a resolution ticket becomes an agent comment" do
    issue = issues(:two)

    perform triage_ticket(issue), triage_article(article_type: :agent_portal_comment, body: "Odpoveď agenta"), ticket_id: 3

    assert_kind_of Issues::AgentComment, issue.comments.last
    assert_equal "Odpoveď agenta", issue.comments.last.text
  end

  test "article already imported is not imported twice" do
    issue = issues(:two)
    issues_comments(:two_comment1).update_columns(triage_external_id: 7)

    assert_no_difference -> { issue.comments.count } do
      perform triage_ticket(issue), triage_article(article_type: :agent_portal_comment), ticket_id: 3
    end
  end

  test "articles of other types are ignored" do
    assert_no_difference -> { Issues::Comment.count } do
      perform triage_ticket(issues(:two)), nil, ticket_id: 3
    end
  end

  test "tickets not from the portal or missing raise" do
    assert_raises(RuntimeError) { perform triage_ticket(issues(:two), origin: "email"), nil, ticket_id: 3 }
    assert_raises(RuntimeError) { perform nil, nil, ticket_id: 3 }
  end
end
