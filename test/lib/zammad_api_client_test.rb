require "test_helper"
require "test_helpers/triage_helper"
require "test_helpers/zammad_helper"

class ZammadApiClientTest < ActiveSupport::TestCase
  include TriageHelper
  include ZammadHelper

  ALL_ARTICLE_TYPES = %i[
    unknown_user_portal_comment user_portal_comment agent_portal_comment agent_portal_and_backoffice_comment
    responsible_subject_portal_and_backoffice_comment agent_backoffice_comment
    user_private_comment agent_private_comment user_attachment_update system_note
  ]

  setup do
    @client = ZammadApiClient.new(url: ENV.fetch("TRIAGE_ZAMMAD_URL"), http_token: "token")
  end

  # get_ticket

  test "get_ticket returns nil when the ticket does not exist" do
    stub_zammad(:get, "tickets/42", status: 404, body: zammad_not_found("Ticket"))

    assert_nil @client.get_ticket(42)
  end

  test "get_ticket re-raises other Zammad errors" do
    stub_zammad(:get, "tickets/42", status: 500, body: { error: "Internal Server Error" })

    assert_raises(RuntimeError) { @client.get_ticket(42) }
  end

  test "get_ticket ignores tickets that did not originate on the portal" do
    stub_ticket(origin: nil)

    assert_nil @client.get_ticket(42)
  end

  test "get_ticket raises for an unsupported process type" do
    stub_ticket(process_type: "backoffice_subtask")

    error = assert_raises(RuntimeError) { @client.get_ticket(42) }
    assert_equal "Process type not yet supported: backoffice_subtask", error.message
  end

  test "get_ticket raises when the ticket has no municipality" do
    stub_ticket(address_municipality: "")

    error = assert_raises(RuntimeError) { @client.get_ticket(42) }
    assert_equal "Ticket from triage 42 is missing address municipality", error.message
  end

  test "get_ticket maps a resolution ticket to portal records" do
    stub_ticket(
      responsible_subject: rs_value(responsible_subjects(:one)),
      previous_responsible_subject: rs_value(responsible_subjects(:two))
    )

    ticket = @client.get_ticket(42)

    assert_equal 42, ticket[:triage_identifier]
    assert_equal issues_states(:in_progress), ticket[:ops_state]
    assert_equal municipalities(:bratislava), ticket[:municipality]
    assert_equal municipality_districts(:stare_mesto_ba), ticket[:municipality_district]
    assert_equal issues_categories(:one), ticket[:category]
    assert_equal issues_subcategories(:one), ticket[:subcategory]
    assert_equal issues_subtypes(:one), ticket[:subtype]
    assert_equal responsible_subjects(:one), ticket[:responsible_subject]
    assert_equal responsible_subjects(:two), ticket[:previous_responsible_subject]
    assert_equal users(:one), ticket[:author]
    assert_equal({ firstname: "Jozef", lastname: "Mokry", uuid: users(:one).uuid }, ticket[:author_response])
    assert_not_requested :get, zammad_url("ticket_articles/by_ticket/42"), query: hash_including({})
  end

  test "get_ticket returns the same keys the job tests fake with TriageHelper#triage_ticket" do
    stub_ticket

    ticket = @client.get_ticket(42)

    assert_equal (triage_ticket(issues(:one)).keys + [ :author_response ]).sort, ticket.keys.sort
  end

  test "get_ticket hides the author of an anonymous ticket" do
    stub_ticket(anonymous: true)

    assert_nil @client.get_ticket(42)[:author]
  end

  test "get_ticket with expand returns public articles as activities" do
    stub_ticket
    stub_users
    stub_zammad(:get, "ticket_attachment/42/101/501", body: "image-bytes")

    activities = @client.get_ticket(42, expand: true)[:activities]

    assert_equal [ 101, 102 ], activities.map { it[:triage_identifier] }

    citizen_comment, agent_comment = activities
    assert_equal :user_portal_comment, citizen_comment[:article_type]
    assert_equal users(:one), citizen_comment[:author]
    assert_equal [ { triage_identifier: 501, filename: "lavicka.jpg", content_type: "image/jpeg", data64: Base64.strict_encode64("image-bytes") } ],
      citizen_comment[:attachments]

    assert_equal :agent_portal_comment, agent_comment[:article_type]
    assert_equal "Podnet sme odstúpili mestskej časti.", agent_comment[:body]
    assert_equal ZammadApiClient::DEFAULT_OPS_ADMIN_USER, agent_comment[:author_response]
  end

  test "get_ticket for a praise returns only the first article as the citizen's comment" do
    stub_ticket(issue_type: "praise")
    stub_zammad(:get, "ticket_attachment/42/101/501", body: "image-bytes")
    stub_zammad(:get, "ticket_attachment/42/101/502", body: "<p>html</p>")

    activities = @client.get_ticket(42)[:activities]

    assert_equal 1, activities.size
    assert_equal :user_portal_comment, activities.first[:article_type]
    assert_equal 101, activities.first[:triage_identifier]
    assert_equal "Lavička na námestí má odlomené dosky a nedá sa na nej sedieť.", activities.first[:body]
  end

  test "get_ticket maps a verification ticket" do
    stub_ticket(process_type: "portal_issue_verification", issue_resolved: "yes")

    ticket = @client.get_ticket(42)

    assert_equal "portal_issue_verification", ticket[:process_type]
    assert_equal "yes", ticket[:issue_resolved]
    assert_equal "Dobrovoľníci::Bratislava", ticket[:triage_group]
  end

  # get_article

  test "get_article returns nil when the ticket does not exist" do
    stub_zammad(:get, "tickets/42", status: 404, body: zammad_not_found("Ticket"))

    assert_nil @client.get_article(42, 101)
  end

  test "get_article returns nil when the article is not on the ticket" do
    stub_ticket

    assert_nil @client.get_article(42, 999)
  end

  test "get_article strips triage tags from the body" do
    stub_article(sender: "Agent", created_by_id: 3, origin_by_id: nil, body: "[[ops portal]] Opravené. [[vyriešené]] ")

    assert_equal "Opravené.", @client.get_article(42, 110)[:body]
  end

  # Article classification

  test "internal articles are never published" do
    assert_nil article_type(internal: true)
  end

  test "system articles are system notes" do
    assert_equal :system_note, article_type(sender: "System")
  end

  test "triage process articles" do
    assert_equal :user_private_comment, article_type(process_type: "portal_issue_triage", sender: "Customer", type: "web")
    assert_equal :user_attachment_update, article_type(process_type: "portal_issue_triage", sender: "Customer", type: "note")
    assert_equal :agent_private_comment, article_type(process_type: "portal_issue_triage", sender: "Agent")
  end

  test "resolution process articles from citizens" do
    assert_equal :user_portal_comment, article_type(sender: "Customer", type: "web", origin_by_id: 1)
    assert_equal :user_portal_comment, article_type(sender: "Customer", type: "note", origin_by_id: 1)
    assert_equal :unknown_user_portal_comment,
      article_type(sender: "Customer", origin_by_id: nil, created_by_id: ENV.fetch("TRIAGE_ZAMMAD_TECH_USER_ID").to_i)
  end

  test "resolution process articles from agents depend on tags" do
    agent = { sender: "Agent", origin_by_id: nil, created_by_id: 3 }
    portal = ZammadApiClient::OPS_PORTAL_ARTICLE_TAG
    backoffice = ZammadApiClient::RESPONSIBLE_SUBJECT_ARTICLE_TAG

    assert_equal :agent_portal_comment, article_type(**agent, body: "#{portal} text")
    assert_equal :agent_backoffice_comment, article_type(**agent, body: "#{backoffice} text")
    assert_equal :agent_portal_and_backoffice_comment, article_type(**agent, body: "#{portal} #{backoffice} text")
    assert_nil article_type(**agent, body: "text without tags")
  end

  test "resolution process article from a customer who is neither citizen nor responsible subject is not published" do
    assert_nil article_type(sender: "Customer", origin_by_id: 3, body: "text without tags")
  end

  test "responsible subject articles are always public" do
    assert_equal :responsible_subject_portal_and_backoffice_comment, article_type(sender: "Customer", type: "email", origin_by_id: 4242)
    assert_equal :responsible_subject_portal_and_backoffice_comment, article_type(sender: "Customer", type: "web", origin_by_id: 4242)
  end

  test "automated emails from responsible subjects are not published" do
    email = { sender: "Customer", type: "email", origin_by_id: 4242 }

    assert_nil article_type(**email, subject: "Automatic reply: out of office")
    assert_nil article_type(**email, subject: "Delivery Status Notification (Failure)")
    assert_nil article_type(**email, from: "MAILER-DAEMON@malacky.sk")
    assert_nil article_type(**email, from: "noreply@malacky.sk")
    assert_nil article_type(**email, preferences: { "Auto-Submitted" => "auto-replied" })
    assert_nil article_type(**email, preferences: { "Auto-Submitted" => "auto-generated" })
  end

  test "regular emails from responsible subjects are published" do
    email = { sender: "Customer", type: "email", origin_by_id: 4242 }

    assert_equal :responsible_subject_portal_and_backoffice_comment,
      article_type(**email, from: "podatelna@malacky.sk", subject: "Re: Podnet", preferences: { "Auto-Submitted" => "no" })
  end

  test "unknown process type raises" do
    error = assert_raises(RuntimeError) { article_type(process_type: "unknown_process") }
    assert_equal "Unknown process type: unknown_process", error.message
  end

  # Responsible subject articles

  test "email from a PRO responsible subject is attributed to it and reduced to the reply" do
    stub_article(
      sender: "Customer", type: "email", origin_by_id: 4242, content_type: "text/html",
      body: File.read(file_fixture("responsible_subject_emails/backoffice_comment.html"))
    )

    article = @client.get_article(42, 110)

    assert_equal responsible_subjects(:pro), article[:author]
    assert_equal 4242, article[:author_response][:responsible_subject_identifier]
    assert_equal "text/plain", article[:content_type]
    assert_equal EmailParser.parse_text(File.read(file_fixture("responsible_subject_emails/backoffice_comment.html"))).strip, article[:body]
  end

  test "email from a member of a responsible subject organization is attributed to that responsible subject" do
    responsible_subjects(:one).update!(external_id: "4343")
    stub_zammad(:get, "users/4343", fixture: "zammad/user_responsible_subject", overrides: { id: 4343, firstname: "MÚ Staré Mesto" })
    stub_article(sender: "Customer", type: "email", origin_by_id: 77, body: "Odpoveď úradu.")

    article = @client.get_article(42, 110)

    assert_equal responsible_subjects(:one), article[:author]
    assert_equal 4343, article[:author_response][:responsible_subject_identifier]
  end

  # Visibility of agent comments meant for the responsible subject

  test "agent backoffice comment is visible to the ticket's responsible subject" do
    stub_backoffice_comment

    assert_equal :agent_backoffice_comment, backoffice_comment_for(responsible_subjects(:one))&.dig(:article_type)
  end

  test "agent backoffice comment is hidden without a responsible subject" do
    stub_backoffice_comment

    assert_nil backoffice_comment_for(nil)
  end

  test "agent backoffice comment is hidden from another responsible subject" do
    stub_backoffice_comment

    assert_nil backoffice_comment_for(responsible_subjects(:two))
  end

  test "agent backoffice comment written before the responsible subject changed is hidden" do
    stub_backoffice_comment(responsible_subject_changed_at: "2024-11-08T00:00:00.000Z")

    assert_nil backoffice_comment_for(responsible_subjects(:one))
  end

  test "agent backoffice comment written after the responsible subject changed is visible" do
    stub_backoffice_comment(responsible_subject_changed_at: "2024-11-06T00:00:00.000Z")

    assert_not_nil backoffice_comment_for(responsible_subjects(:one))
  end

  # create_ticket_from_issue!

  test "create_ticket_from_issue! sends the issue with its photos" do
    stub_zammad(:post, "tickets", status: 201, body: { id: 99 })
    issue = issues(:one)
    issue.municipality_district = municipality_districts(:stare_mesto_ba)
    issue.responsible_subject = responsible_subjects(:one)

    assert_equal 99, @client.create_ticket_from_issue!(issue, issue_number: "P-0001")

    assert_requested :post, zammad_url("tickets"), query: hash_including({}), body: hash_including(
      "number" => "P-0001",
      "ops_issue_identifier" => issue.id,
      "process_type" => "portal_issue_triage",
      "title" => "Rozbitá lavička na námestí",
      "customer_id" => 1,
      "ops_state" => "waiting",
      "address_municipality" => "Bratislava::Staré Mesto",
      "category" => "Zeleň a životné prostredie",
      "responsible_subject" => { "label" => "MÚ Staré Mesto", "value" => responsible_subjects(:one).id },
      "origin" => "portal",
      "article" => hash_including(
        "body" => issue.description,
        "sender" => "Customer",
        "attachments" => [ hash_including("filename" => "graffiti-with-geo.jpg", "mime-type" => "image/jpeg") ]
      )
    )
  end

  test "create_ticket_from_issue! sends a privately resolved praise as unresolved" do
    stub_zammad(:post, "tickets", status: 201, body: { id: 99 })
    issue = issues(:praise)
    issue.issue_type = :praise
    issue.state = issues_states(:resolved_private)

    @client.create_ticket_from_issue!(issue, issue_number: "P-0002")

    assert_requested :post, zammad_url("tickets"), query: hash_including({}), body: hash_including("ops_state" => "unresolved")
  end

  test "create_ticket_from_issue! uses placeholders for a missing title and description" do
    stub_zammad(:post, "tickets", status: 201, body: { id: 99 })
    issue = issues(:praise)
    issue.title = ""
    issue.description = ""

    @client.create_ticket_from_issue!(issue, issue_number: "P-0003")

    assert_requested :post, zammad_url("tickets"), query: hash_including({}),
      body: hash_including("title" => "Bez názvu", "article" => hash_including("body" => "(bez popisu)"))
  end

  # update_ticket!

  test "update_ticket! remembers the previous responsible subject when it changes" do
    stub_ticket(responsible_subject: rs_value(responsible_subjects(:one)))
    stub_zammad(:put, "tickets/42", fixture: "zammad/ticket_resolution")

    @client.update_ticket!(42, { "ops_state" => "sent_to_responsible", "responsible_subject" => rs_value(responsible_subjects(:two)) })

    assert_requested :put, zammad_url("tickets/42"), query: hash_including({}), body: {
      "ops_state" => "sent_to_responsible",
      "responsible_subject" => rs_value(responsible_subjects(:two)).stringify_keys,
      "previous_responsible_subject" => rs_value(responsible_subjects(:one)).stringify_keys
    }
  end

  test "update_ticket! keeps the responsible subject when only the id type differs" do
    stub_ticket(responsible_subject: rs_value(responsible_subjects(:one)))
    stub_zammad(:put, "tickets/42", fixture: "zammad/ticket_resolution")
    same_subject = { label: "MÚ Staré Mesto", value: responsible_subjects(:one).id.to_s }

    @client.update_ticket!(42, { "ops_state" => "in_progress", "responsible_subject" => same_subject })

    assert_requested :put, zammad_url("tickets/42"), query: hash_including({}), body: { "ops_state" => "in_progress" }
  end

  # sync_previous_responsible_subject!

  test "sync_previous_responsible_subject! stores a different responsible subject" do
    stub_ticket(responsible_subject: rs_value(responsible_subjects(:one)))
    stub_zammad(:put, "tickets/42", fixture: "zammad/ticket_resolution")

    @client.sync_previous_responsible_subject!(42, rs_value(responsible_subjects(:two)))

    assert_requested :put, zammad_url("tickets/42"), query: hash_including({}),
      body: { "previous_responsible_subject" => rs_value(responsible_subjects(:two)).stringify_keys }
  end

  test "sync_previous_responsible_subject! skips the current responsible subject" do
    stub_ticket(responsible_subject: rs_value(responsible_subjects(:one)))

    @client.sync_previous_responsible_subject!(42, rs_value(responsible_subjects(:one)))

    assert_not_requested :put, zammad_url("tickets/42"), query: hash_including({})
  end

  # update_ticket_attachments!

  test "update_ticket_attachments! replaces triage attachments that are no longer on the issue" do
    stub_ticket
    delete_jpg = stub_zammad(:delete, "attachments/501")
    delete_html = stub_zammad(:delete, "attachments/502")
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 120 })

    @client.update_ticket_attachments!(42, issues(:one))

    assert_requested delete_jpg
    assert_requested delete_html
    assert_requested :post, zammad_url("ticket_articles"), query: hash_including({}), body: hash_including(
      "ticket_id" => 42,
      "body" => "Aktualizované prílohy",
      "type" => "note",
      "internal" => false,
      "attachments" => [ hash_including("filename" => "graffiti-with-geo.jpg", "mime-type" => "image/jpeg") ]
    )
  end

  test "update_ticket_attachments! does nothing when triage already has the issue photos" do
    issue = issues(:one)
    photo = issue.photos.first
    articles = zammad_fixture("zammad/ticket_articles")
    articles.first["attachments"] = [ {
      "id" => 501,
      "filename" => photo.filename.to_s,
      "size" => photo.variant(:full).processed.image.blob.byte_size.to_s,
      "preferences" => { "Mime-Type" => photo.content_type }
    } ]
    stub_ticket(articles: articles)

    @client.update_ticket_attachments!(42, issue)

    assert_not_requested :delete, %r{/api/v1/attachments/}
    assert_not_requested :post, zammad_url("ticket_articles"), query: hash_including({})
  end

  # create_system_note!

  test "create_system_note! posts an internal system note" do
    stub_ticket(articles: [ zammad_fixture("zammad/article") ])
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 120 })

    assert_equal 120, @client.create_system_note!(42, "Podnet bol zamietnutý.")

    assert_requested :post, zammad_url("ticket_articles"), query: hash_including({}), body: hash_including(
      "ticket_id" => 42, "body" => "Podnet bol zamietnutý.", "internal" => true, "sender" => "System", "type" => "note", "content_type" => "text/plain"
    )
  end

  test "create_system_note! reuses the note when it is already the latest article" do
    stub_ticket(articles: [ system_note(id: 5, body: "Podnet bol zamietnutý.") ])

    assert_equal 5, @client.create_system_note!(42, "Podnet bol zamietnutý.")

    assert_not_requested :post, zammad_url("ticket_articles"), query: hash_including({})
  end

  test "create_system_note! posts the note again when other articles followed it" do
    stub_ticket(articles: [ system_note(id: 5, body: "Podnet bol zamietnutý."), zammad_fixture("zammad/article", id: 7) ])
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 120 })

    assert_equal 120, @client.create_system_note!(42, "Podnet bol zamietnutý.")
  end

  # Users

  test "create_customer! creates a portal user" do
    stub_zammad(:post, "users", status: 201, body: { id: 55 })
    user = users(:one)

    assert_equal 55, @client.create_customer!(user)

    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "firstname" => "Jozef Mokry", "login" => "ops-user-#{user.id}", "roles" => [ "Portal User" ], "origin" => "portal"
    )
  end

  test "create_customer! returns the existing user when the login is taken" do
    user = users(:one)
    stub_zammad(:post, "users", status: 422, body: { error: "Login 'ops-user-#{user.id}' is already used for another user." })
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_portal") ])

    assert_equal 1, @client.create_customer!(user)

    assert_requested :get, zammad_url("users/search"), query: hash_including("query" => "ops-user-#{user.id}")
  end

  test "create_customer! raises when the taken login cannot be found" do
    stub_zammad(:post, "users", status: 422, body: { error: "Login is already used for another user." })
    stub_zammad(:get, "users/search", body: [])

    assert_raises(RuntimeError, match: /Can't find nor create triage zammad user/) { @client.create_customer!(users(:one)) }
  end

  # check_import_mode!

  test "check_import_mode! raises when import mode is off" do
    stub_zammad(:get, "settings", body: [ { name: "import_mode", state_current: { value: false } } ])

    error = assert_raises(RuntimeError) { @client.check_import_mode! }
    assert_equal "Import mode OFF", error.message
  end

  test "check_import_mode! checks Zammad at most once a minute unless forced" do
    settings = stub_zammad(:get, "settings", fixture: "zammad/settings")

    @client.check_import_mode!
    @client.check_import_mode!
    assert_requested settings, times: 1

    @client.check_import_mode!(force: true)
    assert_requested settings, times: 2
  end

  # Links

  test "link_tickets! links the child ticket to its parent" do
    stub_ticket_number(44, "R-0044")
    link = stub_zammad(:post, "links/add", body: {})

    @client.link_tickets!(parent_ticket_id: 42, child_ticket_id: 44)

    assert_requested link.with(body: {
      link_type: "child", link_object_target: "Ticket", link_object_target_value: 42,
      link_object_source: "Ticket", link_object_source_number: "R-0044"
    })
  end

  test "link_tickets! ignores a link that already exists" do
    stub_ticket_number(44, "R-0044")
    stub_zammad(:post, "links/add", status: 422, body: { error: "Link already exists" })

    assert_nothing_raised { @client.link_tickets!(parent_ticket_id: 42, child_ticket_id: 44) }
  end

  test "link_tickets! raises other Zammad errors" do
    stub_ticket_number(44, "R-0044")
    stub_zammad(:post, "links/add", status: 500, body: { error: "boom" })

    error = assert_raises(RuntimeError) { @client.link_tickets!(parent_ticket_id: 42, child_ticket_id: 44) }
    assert_equal "Request failed with status 500", error.message
  end

  test "get_ticket_resolution_parent_links returns only parent resolution tickets" do
    stub_zammad(:get, "links", fixture: "zammad/links")
    stub_zammad(:get, "tickets/42", fixture: "zammad/ticket_resolution")
    stub_zammad(:get, "tickets/43", fixture: "zammad/ticket_resolution", overrides: { id: 43, process_type: "portal_issue_triage" })

    assert_equal [ 42 ], @client.get_ticket_resolution_parent_links(44)
  end

  private

  def stub_ticket(articles: zammad_fixture("zammad/ticket_articles"), **overrides)
    stub_zammad(:get, "tickets/42", fixture: "zammad/ticket_resolution", overrides: overrides)
    stub_zammad(:get, "ticket_articles/by_ticket/42", body: articles)
  end

  def stub_ticket_number(id, number)
    stub_zammad(:get, "tickets/#{id}", fixture: "zammad/ticket_resolution", overrides: { id: id, number: number })
  end

  def stub_users
    stub_zammad(:get, "users/1", fixture: "zammad/user_portal")
    stub_zammad(:get, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:get, "users/77", fixture: "zammad/user_organization_member")
    stub_zammad(:get, "users/4242", fixture: "zammad/user_responsible_subject")
  end

  # A ticket whose only article is article 110, built from the article fixture.
  def stub_article(ticket_overrides = {}, **article)
    stub_ticket(articles: [ zammad_fixture("zammad/article", **article) ], **ticket_overrides)
    stub_users
  end

  def article_type(process_type: "portal_issue_resolution", **article)
    stub_article({ process_type: process_type, responsible_subject: rs_value(responsible_subjects(:one)) }, **article)
    @client.get_article(42, 110, allowed_article_types: ALL_ARTICLE_TYPES, responsible_subject: responsible_subjects(:one))&.dig(:article_type)
  end

  def stub_backoffice_comment(**ticket_overrides)
    stub_article(
      { responsible_subject: rs_value(responsible_subjects(:one)), **ticket_overrides },
      sender: "Agent", origin_by_id: nil, created_by_id: 3, body: "#{ZammadApiClient::RESPONSIBLE_SUBJECT_ARTICLE_TAG} Prosíme o vyjadrenie."
    )
  end

  def backoffice_comment_for(responsible_subject)
    @client.get_article(42, 110, responsible_subject: responsible_subject)
  end

  def system_note(id:, body:)
    zammad_fixture("zammad/article", id: id, sender: "System", type: "note", internal: true, body: body)
  end

  def rs_value(responsible_subject)
    { label: responsible_subject.subject_name, value: responsible_subject.id }
  end
end
