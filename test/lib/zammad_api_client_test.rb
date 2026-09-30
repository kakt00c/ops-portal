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
    assert_nil article_type(**email, preferences: { "is-auto-response" => true, "send-auto-response" => false })
  end

  test "regular emails from responsible subjects are published" do
    email = { sender: "Customer", type: "email", origin_by_id: 4242 }

    assert_equal :responsible_subject_portal_and_backoffice_comment,
      article_type(**email, from: "podatelna@malacky.sk", subject: "Re: Podnet", preferences: { "is-auto-response" => false, "send-auto-response" => true })
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

  test "get_ticket_resolution_parent_links returns nothing for a ticket without links" do
    stub_zammad(:get, "links", body: {})

    assert_equal [], @client.get_ticket_resolution_parent_links(44)
  end

  test "raw_api_request re-raises connection failures" do
    stub_request(:get, zammad_url("settings")).to_timeout

    assert_raises(Faraday::Error) { @client.check_import_mode! }
  end

  # create_ticket_from_issue_update!

  test "create_ticket_from_issue_update! opens a verification ticket linked to the resolution ticket" do
    update = build_issue_update(resolves_issue: true)
    stub_zammad(:get, "tickets/3", fixture: "zammad/ticket_resolution", overrides: { id: 3 })
    stub_zammad(:post, "tickets", status: 201, body: { id: 700 })
    stub_ticket_number(700, update.ticket_number)
    link = stub_zammad(:post, "links/add", body: {})

    assert_equal 700, @client.create_ticket_from_issue_update!(update)

    assert_requested :post, zammad_url("tickets"), query: hash_including({}), body: hash_including(
      "number" => update.ticket_number,
      "ops_issue_identifier" => update.id,
      "process_type" => "portal_issue_verification",
      "title" => "Overenie podnetu Issue from Bratislava",
      "group" => "Dobrovoľníci::Bratislava",
      "owner" => "agent@example.org",
      "customer_id" => 1,
      "ops_state" => "waiting",
      "issue_resolved" => "yes",
      "portal_url" => "#{Rails.application.routes.url_helpers.issue_url(issues(:two))}#komentar_#{update.id}",
      "article" => hash_including(
        "body" => "Lavička je opravená.", "sender" => "Customer", "type" => "web",
        "attachments" => [ hash_including("filename" => "avatar.png", "mime-type" => "image/png") ]
      )
    )
    assert_requested link.with(body: hash_including(link_object_target_value: 3, link_object_source_number: update.ticket_number))
  end

  test "create_ticket_from_issue_update! creates the Zammad customer for an author without one" do
    update = build_issue_update(resolves_issue: false, author: users(:two))
    stub_zammad(:get, "tickets/3", fixture: "zammad/ticket_resolution", overrides: { id: 3 })
    stub_zammad(:post, "users", status: 201, body: { id: 56 })
    stub_zammad(:post, "tickets", status: 201, body: { id: 700 })
    stub_ticket_number(700, update.ticket_number)
    stub_zammad(:post, "links/add", body: {})

    @client.create_ticket_from_issue_update!(update)

    assert_equal 56, users(:two).reload.external_id
    assert_requested :post, zammad_url("tickets"), query: hash_including({}), body: hash_including(
      "title" => "Aktualizácia podnetu Issue from Bratislava", "issue_resolved" => "no", "customer_id" => 56
    )
  end

  # update_ticket_from_issue!

  test "update_ticket_from_issue! sends the current issue fields" do
    stub_ticket
    stub_zammad(:put, "tickets/42", fixture: "zammad/ticket_resolution")
    issue = issues(:one)
    issue.municipality_district = municipality_districts(:stare_mesto_ba)
    issue.responsible_subject = responsible_subjects(:one)

    @client.update_ticket_from_issue!(42, issue)

    assert_requested :put, zammad_url("tickets/42"), query: hash_including({}), body: hash_including(
      "title" => "Rozbitá lavička na námestí",
      "ops_state" => "waiting",
      "address_municipality" => "Bratislava::Staré Mesto",
      "category" => "Zeleň a životné prostredie",
      "subcategory" => "Strom",
      "responsible_subject" => rs_value(responsible_subjects(:one)).stringify_keys
    )
    assert_not_requested :post, zammad_url("ticket_articles"), query: hash_including({})
  end

  test "update_ticket_from_issue! syncs attachments when asked" do
    stub_ticket
    stub_zammad(:put, "tickets/42", fixture: "zammad/ticket_resolution")
    stub_request(:delete, %r{/api/v1/attachments/})
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 120 })

    @client.update_ticket_from_issue!(42, issues(:one), update_attachments: true)

    assert_requested :post, zammad_url("ticket_articles"), query: hash_including({}), body: hash_including("body" => "Aktualizované prílohy")
  end

  # Other ticket updates

  test "update_ticket! sends the investment flag" do
    stub_ticket
    stub_zammad(:put, "tickets/42", fixture: "zammad/ticket_resolution")

    @client.update_ticket!(42, { "investment" => "yes" })

    assert_requested :put, zammad_url("tickets/42"), query: hash_including({}), body: { "investment" => "yes" }
  end

  test "close_ticket! closes the ticket" do
    stub_ticket
    stub_zammad(:put, "tickets/42", fixture: "zammad/ticket_resolution")

    @client.close_ticket!(42)

    assert_requested :put, zammad_url("tickets/42"), query: hash_including({}), body: { "state" => "closed" }
  end

  test "find_ticket_responsible_subject returns the ticket's responsible subject" do
    stub_ticket(responsible_subject: rs_value(responsible_subjects(:one)))

    assert_equal rs_value(responsible_subjects(:one)), @client.find_ticket_responsible_subject(42)
  end

  # Creating articles

  test "create_article! posts a portal comment with its attachments" do
    comment = issues_comments(:one_comment1)
    comment.update!(text: "Stále to nie je opravené.")
    comment.attachments.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    stub_ticket
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 120 })

    assert_equal 120, @client.create_article!(42, comment, sender: "Customer")

    assert_requested :post, zammad_url("ticket_articles"), query: hash_including({}), body: hash_including(
      "ticket_id" => 42,
      "uuid" => comment.uuid,
      "origin_by_id" => 1,
      "content_type" => "text/html",
      "body" => "Stále to nie je opravené.",
      "type" => "web",
      "sender" => "Customer",
      "attachments" => [ hash_including("filename" => "avatar.png", "mime-type" => "image/png") ]
    )
  end

  test "create_article! uses a placeholder for an empty comment" do
    stub_ticket
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 120 })

    @client.create_article!(42, issues_comments(:one_comment1), sender: "Customer")

    assert_requested :post, zammad_url("ticket_articles"), query: hash_including({}), body: hash_including("body" => "(bez popisu)")
  end

  test "create_article! raises when Zammad returns no article id" do
    stub_ticket
    stub_zammad(:post, "ticket_articles", status: 201, body: {})

    error = assert_raises(RuntimeError) { @client.create_article!(42, issues_comments(:one_comment1), sender: "Customer") }
    assert_equal "No article ID returned", error.message
  end

  test "create_rs_portal_article! posts the comment as an email from the responsible subject" do
    comment = issues_comments(:one_comment1)
    comment.update!(text: "Opravu sme naplánovali.")
    comment.attachments.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    stub_ticket
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 121 })

    assert_equal 121, @client.create_rs_portal_article!(42, comment)

    assert_requested :post, zammad_url("ticket_articles"), query: hash_including({}), body: hash_including(
      "ticket_id" => 42,
      "content_type" => "text/plain",
      "body" => "Opravu sme naplánovali.",
      "type" => "email",
      "to" => "portal.responsible.subjects@odkazprestarostu.sk",
      "sender" => "Customer",
      "attachments" => [ hash_including("filename" => "avatar.png", "mime-type" => "image/png") ]
    )
  end

  test "create_article_from_api! posts a public note from the backoffice" do
    stub_ticket
    stub_zammad(:post, "ticket_articles", status: 201, body: { id: 122 })
    activity = {
      "content_type" => "text/plain",
      "body" => "Odpoveď z backoffice.",
      "created_at" => "2024-11-07T08:00:00.000Z",
      "attachments" => [ { "filename" => "photo.jpg", "content_type" => "image/jpeg", "data64" => "aW1hZ2U=" } ]
    }

    assert_equal 122, @client.create_article_from_api!(4242, 42, activity)

    assert_requested :post, zammad_url("ticket_articles"), query: hash_including({}), body: hash_including(
      "ticket_id" => 42,
      "origin_by_id" => 4242,
      "content_type" => "text/plain",
      "body" => "Odpoveď z backoffice.",
      "type" => "note",
      "internal" => false,
      "attachments" => [ { "filename" => "photo.jpg", "mime-type" => "image/jpeg", "data" => "aW1hZ2U=" } ]
    )
  end

  # Reading articles and tickets: remaining edge cases

  test "get_article re-raises other Zammad errors" do
    stub_zammad(:get, "tickets/42", status: 500, body: { error: "Internal Server Error" })

    assert_raises(RuntimeError) { @client.get_article(42, 101) }
  end

  test "get_ticket leaves the author empty when the customer is not a portal user" do
    stub_ticket(customer_id: 999, created_by_id: 999)

    ticket = @client.get_ticket(42)

    assert_nil ticket[:author]
    assert_nil ticket[:author_response]
  end

  test "get_article raises for a responsible subject author that cannot be matched to a responsible subject" do
    stub_zammad(:get, "users/5000", fixture: "zammad/user_responsible_subject", overrides: { id: 5000 })
    stub_article(sender: "Customer", type: "email", origin_by_id: 5000)

    error = assert_raises(RuntimeError) { @client.get_article(42, 110) }
    assert_equal "Responsible subject article author has no organization", error.message
  end

  # Users

  test "get_users lists Zammad users" do
    stub_zammad(:get, "users", body: [ zammad_fixture("zammad/user_portal"), zammad_fixture("zammad/user_agent") ])

    assert_equal [ 1, 3 ], @client.get_users.first(2).map(&:id)
  end

  test "find_user returns the Zammad user" do
    stub_zammad(:get, "users/1", fixture: "zammad/user_portal")

    assert_equal "ops-user-1", @client.find_user(1).login
  end

  test "find_user returns nil when the user does not exist" do
    stub_zammad(:get, "users/1", status: 404, body: zammad_not_found("User"))

    assert_nil @client.find_user(1)
  end

  test "find_user re-raises other Zammad errors" do
    stub_zammad(:get, "users/1", status: 500, body: { error: "Internal Server Error" })

    assert_raises(RuntimeError) { @client.find_user(1) }
  end

  test "add_user_to_group grants full access to the group and keeps existing groups" do
    stub_zammad(:get, "users/3", fixture: "zammad/user_agent")
    stub_zammad(:put, "users/3", fixture: "zammad/user_agent")

    @client.add_user_to_group(3, "Dobrovoľníci::Bratislava")

    assert_requested :put, zammad_url("users/3"), query: hash_including({}),
      body: { "groups" => { "Incoming" => "full", "Dobrovoľníci::Bratislava" => "full" } }
  end

  test "update_customer renames the portal user in Zammad" do
    user = users(:one)
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_portal", firstname: "Staré meno") ])
    stub_zammad(:put, "users/1", fixture: "zammad/user_portal")

    @client.update_customer(user)

    assert_requested :put, zammad_url("users/1"), query: hash_including({}), body: { "firstname" => "Jozef Mokry" }
  end

  test "update_customer clears the last name of an anonymous user" do
    user = users(:one)
    user.anonymous = true
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_portal", lastname: "Mokry") ])
    stub_zammad(:put, "users/1", fixture: "zammad/user_portal")

    @client.update_customer(user)

    assert_requested :put, zammad_url("users/1"), query: hash_including({}), body: hash_including("lastname" => "")
  end

  test "update_customer returns false when the user is not in Zammad" do
    stub_zammad(:get, "users/search", body: [])

    assert_equal false, @client.update_customer(users(:one))
  end

  test "create_agent! creates an agent" do
    stub_zammad(:post, "users", status: 201, body: { id: 57 })
    user = users(:one)

    assert_equal 57, @client.create_agent!(user)

    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "firstname" => "Jozef", "lastname" => "Mokry", "login" => user.email, "email" => user.email, "roles" => [ "Agent" ]
    )
  end

  test "create_agent! returns the existing user when the email belongs to a user with another login" do
    user = users(:one)
    stub_zammad(:post, "users", status: 422, body: { error: "Email address '#{user.email}' is already used for another user." })
    stub_zammad(:get, "users/search", body: [ zammad_fixture("zammad/user_agent") ])

    assert_equal 3, @client.create_agent!(user)

    assert_requested :get, zammad_url("users/search"), query: hash_including("query" => user.email)
  end

  test "create_agent! raises when the taken email cannot be found" do
    stub_zammad(:post, "users", status: 422, body: { error: "Email address '#{users(:one).email}' is already used for another user." })
    stub_zammad(:get, "users/search", body: [])

    assert_raises(RuntimeError, match: /Can't find nor create triage zammad user with email/) { @client.create_agent!(users(:one)) }
  end

  test "create_agent! re-raises other Zammad errors" do
    stub_zammad(:post, "users", status: 422, body: { error: "Invalid email" })

    assert_raises(RuntimeError, match: /Invalid email/) { @client.create_agent!(users(:one)) }
  end

  test "create_responsible_subject! creates a responsible subject user" do
    stub_zammad(:post, "users", status: 201, body: { id: 58 })
    responsible_subject = responsible_subjects(:one)

    assert_equal 58, @client.create_responsible_subject!(responsible_subject)

    assert_requested :post, zammad_url("users"), query: hash_including({}), body: hash_including(
      "firstname" => "MÚ Staré Mesto", "login" => "ops-rs-#{responsible_subject.id}", "roles" => [ "Zodpovedný Subjekt" ]
    )
  end

  test "get_groups lists Zammad groups" do
    groups = stub_zammad(:get, "groups", body: [ { id: 1, name: "Incoming" }, { id: 2, name: "Dobrovoľníci::Bratislava" } ])

    assert_equal [ "Incoming", "Dobrovoľníci::Bratislava" ], @client.get_groups.map(&:name)
    assert_requested groups.with(query: hash_including("per_page" => "500"))
  end

  private

  def build_issue_update(resolves_issue:, author: users(:one))
    update = Issues::Update.new(text: "Lavička je opravená.", author: author, published: true, resolves_issue: resolves_issue, legacy_id: 1)
    update.build_activity(issue: issues(:two), type: Issues::UpdateActivity)
    update.attachments.attach(io: file_fixture("avatar.png").open, filename: "avatar.png", content_type: "image/png")
    update.save!
    update
  end

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
