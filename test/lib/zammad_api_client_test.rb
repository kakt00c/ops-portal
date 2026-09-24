require "test_helper"
class ZammadApiClientTest < ActiveSupport::TestCase
  class DummyUserClient
    def initialize(user)
      @user = user
    end

    def find(_id)
      @user
    end
  end

  def setup
    @subject = ZammadApiClient.new(url: "http://example.com", http_token: "token")
    @subject.instance_variable_set(:@client, nil)

    @article_struct = Struct.new(:internal, :sender, :type, :origin_by_id, :created_by_id, :body, :organization, :from, :subject, :preferences) do
      def initialize(internal: false, sender: nil, type: nil, origin_by_id: nil, created_by_id: nil, body: "hello", organization: nil, from: nil, subject: nil, preferences: {})
        super
      end
    end
  end

  test "internal article returns nil" do
    article = @article_struct.new(internal: true)
    assert_nil @subject.send(:get_article_type, article, "portal_issue_resolution")
  end

  test "system sender returns system note" do
    article = @article_struct.new(sender: "System")
    assert_equal :system_note, @subject.send(:get_article_type, article, "portal_issue_resolution")
  end

  test "portal_issue_triage process_type web article from customer returns user_private_comment" do
    article = @article_struct.new(sender: "Customer", type: "web")
    assert_equal :user_private_comment, @subject.send(:get_article_type, article, "portal_issue_triage")
  end

  test "portal_issue_triage process_type attachment update note article from customer returns nil" do
    article = @article_struct.new(sender: "Customer", type: "note")
    assert_equal :user_attachment_update, @subject.send(:get_article_type, article, "portal_issue_triage")
  end

  test "portal_issue_triage process_type web article from agent returns agent_private_comment" do
    article = @article_struct.new(sender: "Agent")
    assert_equal :agent_private_comment, @subject.send(:get_article_type, article, "portal_issue_triage")
  end

  test "portal_issue_resolution process_type web article from unknown customer returns unknown_user_portal_comment" do
    article = @article_struct.new(sender: "Customer", origin_by_id: nil, created_by_id: ENV.fetch("TRIAGE_ZAMMAD_TECH_USER_ID").to_i)
    assert_equal :unknown_user_portal_comment, @subject.send(:get_article_type, article, "portal_issue_resolution")
  end

  test "portal_issue_resolution process_type article from agent returns agent_portal_and_backoffice_comment" do
    article = @article_struct.new(sender: "Agent", body: "text with #{ZammadApiClient::OPS_PORTAL_ARTICLE_TAG} and #{ZammadApiClient::RESPONSIBLE_SUBJECT_ARTICLE_TAG}")
    zammad_user = OpenStruct.new(origin: "portal", roles: [ "Agent" ])
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :agent_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "portal_issue_resolution process_type article from agent returns agent_portal_comment" do
    article = @article_struct.new(sender: "Agent", body: "text with #{ZammadApiClient::OPS_PORTAL_ARTICLE_TAG}")
    zammad_user = OpenStruct.new(origin: "portal", roles: [ "Agent" ])
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :agent_portal_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "portal_issue_resolution process_type article from agent returns agent_backoffice_comment" do
    article = @article_struct.new(sender: "Agent", body: "text with #{ZammadApiClient::RESPONSIBLE_SUBJECT_ARTICLE_TAG}")
    zammad_user = OpenStruct.new(origin: "portal", roles: [ "Agent" ])
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :agent_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "portal_issue_resolution process_type web article from customer with portal tag returns user_portal_comment" do
    article = @article_struct.new(sender: "Customer", type: "web", origin_by_id: 456)
    zammad_user = OpenStruct.new(origin: "portal", roles: nil)
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :user_portal_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "portal_issue_resolution process_type note article from customer with portal tag returns user_portal_comment" do
    article = @article_struct.new(sender: "Customer", type: "note", origin_by_id: 456)
    zammad_user = OpenStruct.new(origin: "portal", roles: nil)
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :user_portal_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "portal_issue_resolution process_type article from customer with backoffice tag returns responsible_subject_portal_and_backoffice_comment" do
    article = @article_struct.new(sender: "Customer", body: "text with #{ZammadApiClient::OPS_PORTAL_ARTICLE_TAG}", origin_by_id: 123)
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :responsible_subject_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "portal_issue_resolution process_type article from responsible subject without portal tag is public" do
    article = @article_struct.new(sender: "Customer", origin_by_id: 123)
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :responsible_subject_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "portal_issue_resolution process_type article from customer with other tag returns nil" do
    article = @article_struct.new(sender: "Customer", origin_by_id: 123)
    zammad_user = OpenStruct.new(origin: nil, roles: [ "Other Role" ])
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_nil @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "customer portal origin returns user_portal_comment" do
    article = @article_struct.new(sender: "Customer", origin_by_id: 456)
    zammad_user = OpenStruct.new(origin: "portal", roles: nil)
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :user_portal_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "unknown process type raises error" do
    article = @article_struct.new
    error = assert_raises(RuntimeError) do
      @subject.send(:get_article_type, article, "unknown_process")
    end
    assert_equal "Unknown process type: unknown_process", error.message
  end

  test "email from responsible subject without portal tag is public" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, body: File.read("test/fixtures/files/responsible_subject_emails/backoffice_comment.html"))
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :responsible_subject_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "email from responsible subject with portal tag in the main part returns responsible_subject_portal_and_backoffice_comment" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, body: File.read("test/fixtures/files/responsible_subject_emails/backoffice_and_portal_comment.html"))
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :responsible_subject_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "email from responsible subject with portal tag in the footer is public" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, body: File.read("test/fixtures/files/responsible_subject_emails/backoffice_comment_with_tag_in_history.html"))
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :responsible_subject_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "article from PRO responsible subject without portal tag is public" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, body: "Some text without portal tag")
    zammad_user = OpenStruct.new(origin: nil, organization: nil, roles: [ "Zodpovedný Subjekt" ])
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :responsible_subject_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "article from PRO responsible subject with portal tag in the main part returns responsible_subject_portal_and_backoffice_comment" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, body: "[[ops portal]] Some text with portal tag")
    zammad_user = OpenStruct.new(origin: nil, organization: nil, roles: [ "Zodpovedný Subjekt" ])
    zammad_user_client = DummyUserClient.new(zammad_user)
    zammad_api_client = OpenStruct.new(user: zammad_user_client)
    assert_equal :responsible_subject_portal_and_backoffice_comment, @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "automatic responsible subject email is not published" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, from: "mail@example.sk", subject: "Automatic reply: out of office")
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_api_client = OpenStruct.new(user: DummyUserClient.new(zammad_user))

    assert_nil @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "delivery failure email from responsible subject is not published" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, from: "mail-daemon@example.sk", subject: "Delivery status notification")
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_api_client = OpenStruct.new(user: DummyUserClient.new(zammad_user))

    assert_nil @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "Auto-Submitted responsible subject email is not published" do
    article = @article_struct.new(sender: "Customer", type: "email", origin_by_id: 123, preferences: { "Auto-Submitted" => "auto-replied" })
    zammad_user = OpenStruct.new(origin: nil, organization: "Responsible Subject")
    zammad_api_client = OpenStruct.new(user: DummyUserClient.new(zammad_user))

    assert_nil @subject.send(:get_article_type, article, "portal_issue_resolution", zammad_api_client: zammad_api_client)
  end

  test "create_system_note! returns existing article id when matching note is the most recent article" do
    note_body = "Test system note"
    article = OpenStruct.new(id: 5, internal: true, sender: "System", body: note_body)
    ticket = OpenStruct.new(articles: [ article ])
    ticket_client = Minitest::Mock.new
    ticket_client.expect :find, ticket, [ 1 ]
    @subject.instance_variable_set(:@client, OpenStruct.new(ticket: ticket_client))

    assert_equal 5, @subject.create_system_note!(1, note_body)
    ticket_client.verify
  end

  test "create_system_note! creates new note when matching note exists but is not the most recent article" do
    note_body = "Test system note"
    old_article = OpenStruct.new(id: 3, internal: true, sender: "System", body: note_body)
    newer_article = OpenStruct.new(id: 7, internal: false, sender: "Customer", body: "Reopen comment")
    new_article = OpenStruct.new(id: 9)

    ticket = Object.new
    ticket.define_singleton_method(:articles) { [ old_article, newer_article ] }
    ticket.define_singleton_method(:article) { |**_| new_article }

    ticket_client = Minitest::Mock.new
    ticket_client.expect :find, ticket, [ 1 ]
    @subject.instance_variable_set(:@client, OpenStruct.new(ticket: ticket_client))

    assert_equal 9, @subject.create_system_note!(1, note_body)
  end

  test "create_system_note! creates new note when no matching note exists" do
    note_body = "Test system note"
    other_article = OpenStruct.new(id: 3, internal: false, sender: "Customer", body: "Something else")
    new_article = OpenStruct.new(id: 9)

    ticket = Object.new
    ticket.define_singleton_method(:articles) { [ other_article ] }
    ticket.define_singleton_method(:article) { |**_| new_article }

    ticket_client = Minitest::Mock.new
    ticket_client.expect :find, ticket, [ 1 ]
    @subject.instance_variable_set(:@client, OpenStruct.new(ticket: ticket_client))

    assert_equal 9, @subject.create_system_note!(1, note_body)
  end

  test "link_tickets! silently ignores 422 duplicate link error" do
    child_ticket = OpenStruct.new(number: "R-0001")
    ticket_client = Minitest::Mock.new
    ticket_client.expect :find, child_ticket, [ 2 ]
    @subject.instance_variable_set(:@client, OpenStruct.new(ticket: ticket_client))

    @subject.stub :raw_api_request, ->(*) { raise RuntimeError, "Request failed with status 422" } do
      assert_nothing_raised { @subject.link_tickets!(parent_ticket_id: 1, child_ticket_id: 2) }
    end
  end

  test "link_tickets! re-raises non-422 errors" do
    child_ticket = OpenStruct.new(number: "R-0001")
    ticket_client = Minitest::Mock.new
    ticket_client.expect :find, child_ticket, [ 2 ]
    @subject.instance_variable_set(:@client, OpenStruct.new(ticket: ticket_client))

    @subject.stub :raw_api_request, ->(*) { raise RuntimeError, "Request failed with status 500" } do
      assert_raises(RuntimeError) { @subject.link_tickets!(parent_ticket_id: 1, child_ticket_id: 2) }
    end
  end

  test "strip_tags_from_article_body removes all tags" do
    body = "[[pre zodpovedny subjekt]] \nThis is a test body with tags [[ops portal]], [[vyriesene]], and [[odstúpený]].  "
    stripped_body = @subject.send(:strip_tags_from_article_body, body)
    assert_equal "This is a test body with tags , , and .", stripped_body
  end
end
