require "test_helper"
require "test_helpers/zammad_helper"

class Connector::ZammadApiClientTest < ActiveSupport::TestCase
  include ZammadHelper

  CITIZEN_UUID = "c7a1d6a2-3b4e-4f5a-9b8c-7d6e5f4a3b2c"
  ADMIN_UUID = ZammadApiClient::DEFAULT_OPS_ADMIN_USER[:uuid]

  setup do
    @tenant = connector_tenants(:default)
    @client = Connector::ZammadApiClient.new(@tenant)
  end

  # create_issue!

  test "create_issue! creates the ticket with its first activity and adds the other activities" do
    stub_backoffice_user_creation
    stub_backoffice(:post, "tickets", status: 201, fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
    stub_backoffice(:post, "ticket_articles", status: 201, body: { id: 602 })

    @client.create_issue!(issue_payload)

    assert_requested :post, backoffice_url("tickets"), query: hash_including({}), body: hash_including(
      "number" => "OPS-0001",
      "state" => "new",
      "group" => "Incoming",
      "origin" => "ops",
      "title" => "Rozbitá lavička na námestí",
      "ops_state" => "sent_to_responsible",
      "ops_issue_identifier" => 1,
      "ops_responsible_subject" => { "label" => "Mesto Malacky", "value" => 1 },
      "customer_id" => 900,
      "origin_by_id" => 900,
      "address_municipality" => "Bratislava",
      "address_municipality_district" => "Staré Mesto",
      "ops_portal_url" => "http://localhost:3000/podnety/1",
      "article" => hash_including(
        "origin_by_id" => 900,
        "body" => "Lavička na námestí má odlomené dosky.",
        "type" => "web",
        "sender" => "Customer",
        "attachments" => [ { "filename" => "lavicka.jpg", "mime-type" => "image/jpeg", "data" => "aW1hZ2U=" } ]
      )
    )
    assert_requested :post, backoffice_url("ticket_articles"), query: hash_including({}), body: hash_including(
      "ticket_id" => 500,
      "uuid" => "5b0e6a7c-3f6d-4d1e-8c7a-1d2e3f4a5b6c",
      "origin_by_id" => 901,
      "body" => "Podnet sme odstúpili.",
      "type" => "note",
      "internal" => false,
      "sender" => "Customer"
    )
    assert_equal 500, @tenant.issues.find_by!(triage_external_id: 42).backoffice_external_id
    assert_equal 600, @tenant.activities.find_by!(triage_external_id: 42).backoffice_external_id
    assert_equal 602, @tenant.activities.find_by!(triage_external_id: 102).backoffice_external_id
    assert_equal 900, @tenant.users.find_by!(uuid: CITIZEN_UUID).external_id
  end

  test "create_issue! sends an anonymous issue as the anonymous backoffice user" do
    stub_backoffice(:post, "tickets", status: 201, fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
    payload = issue_payload(author: nil)
    payload["activities"] = [ citizen_activity(author: nil) ]

    @client.create_issue!(payload)

    assert_requested :post, backoffice_url("tickets"), query: hash_including({}),
      body: hash_including("customer_id" => 1, "origin_by_id" => 1, "article" => hash_including("origin_by_id" => 1))
    assert_not_requested :post, backoffice_url("users"), query: hash_including({})
  end

  test "create_issue! reuses a synced ticket and only adds new activities" do
    @tenant.issues.create!(triage_external_id: 42, backoffice_external_id: 500)
    @tenant.activities.create!(triage_external_id: 42, backoffice_external_id: 600)
    @tenant.users.create!(uuid: ADMIN_UUID, external_id: 901)
    stub_synced_ticket
    stub_backoffice(:post, "ticket_articles", status: 201, body: { id: 602 })

    @client.create_issue!(issue_payload)

    assert_not_requested :post, backoffice_url("tickets"), query: hash_including({})
    assert_requested :post, backoffice_url("ticket_articles"), query: hash_including({}), times: 1
  end

  test "create_issue! does nothing for an issue that is already fully synced" do
    @tenant.issues.create!(triage_external_id: 42, backoffice_external_id: 500)
    @tenant.activities.create!(triage_external_id: 42, backoffice_external_id: 600)
    @tenant.activities.create!(triage_external_id: 102, backoffice_external_id: 601)
    stub_synced_ticket

    @client.create_issue!(issue_payload)

    assert_not_requested :post, backoffice_url("tickets"), query: hash_including({})
    assert_not_requested :post, backoffice_url("ticket_articles"), query: hash_including({})
  end

  test "create_issue! adopts an existing ticket with the same number" do
    stub_backoffice_user_creation
    stub_backoffice(:post, "tickets", status: 422, body: { error: "This object already exists." })
    stub_backoffice(:get, "tickets/search", body: [
      zammad_fixture("zammad/backoffice_ticket"),
      zammad_fixture("zammad/backoffice_ticket", id: 510, number: "OPS-00010")
    ])
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
    stub_backoffice(:post, "ticket_articles", status: 201, body: { id: 602 })

    @client.create_issue!(issue_payload)

    assert_requested :get, backoffice_url("tickets/search"), query: hash_including("query" => "\"OPS-0001\"")
    assert_equal 500, @tenant.issues.find_by!(triage_external_id: 42).backoffice_external_id
  end

  test "create_issue! refuses to pick between several tickets with the same number" do
    stub_backoffice_user_creation
    stub_backoffice(:post, "tickets", status: 422, body: { error: "This object already exists." })
    stub_backoffice(:get, "tickets/search", body: [
      zammad_fixture("zammad/backoffice_ticket"), zammad_fixture("zammad/backoffice_ticket", id: 510)
    ])

    error = assert_raises(RuntimeError) { @client.create_issue!(issue_payload) }
    assert_equal "Found multiple matches for ticket!", error.message
  end

  test "create_issue! reuses the backoffice customer when the login is already taken" do
    stub_backoffice(:post, "users", status: 422, body: { error: "Login '#{CITIZEN_UUID}' is already used for another user." })
    stub_backoffice(:get, "users/search", body: [ zammad_fixture("zammad/backoffice_agent", id: 900) ])
    stub_backoffice(:post, "tickets", status: 201, fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
    payload = issue_payload
    payload["activities"] = [ citizen_activity ]

    @client.create_issue!(payload)

    assert_requested :get, backoffice_url("users/search"), query: hash_including("query" => CITIZEN_UUID)
    assert_equal 900, @tenant.users.find_by!(uuid: CITIZEN_UUID).external_id
  end

  # update_issue!

  test "update_issue! sends the portal fields to the ticket" do
    @tenant.issues.create!(triage_external_id: 42, backoffice_external_id: 500)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:put, "tickets/500", fixture: "zammad/backoffice_ticket")

    @client.update_issue!(42, issue_payload(
      ops_state: "resolved",
      responsible_subject: { "label" => "BVS", "value" => 2 },
      likes_count: 5,
      address_municipality: "Malacky",
      address_street: "Záhorácka"
    ))

    assert_requested :put, backoffice_url("tickets/500"), query: hash_including({}), body: hash_including(
      "ops_state" => "resolved",
      "ops_responsible_subject" => { "label" => "BVS", "value" => 2 },
      "ops_likes_count" => 5,
      "ops_category" => "Zeleň a životné prostredie",
      "address_municipality" => "Malacky",
      "address_municipality_district" => "",
      "address_street" => "Záhorácka"
    )
    assert_requested(:put, backoffice_url("tickets/500"), query: hash_including({})) { |request| !JSON.parse(request.body).key?("title") }
  end

  test "update_issue! creates the ticket for an issue the backoffice does not have yet" do
    stub_backoffice_user_creation
    stub_backoffice(:post, "tickets", status: 201, fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
    stub_backoffice(:post, "ticket_articles", status: 201, body: { id: 602 })

    @client.update_issue!(42, issue_payload)

    assert_equal 500, @tenant.issues.find_by!(triage_external_id: 42).backoffice_external_id
  end

  # create_activity!

  test "create_activity! adds the activity to the issue's ticket" do
    @tenant.issues.create!(triage_external_id: 42, backoffice_external_id: 500)
    @tenant.users.create!(uuid: ADMIN_UUID, external_id: 901)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:post, "ticket_articles", status: 201, body: { id: 603 })

    @client.create_activity!(42, agent_activity(triage_identifier: 103, body: "Doplnenie."))

    assert_requested :post, backoffice_url("ticket_articles"), query: hash_including({}),
      body: hash_including("ticket_id" => 500, "origin_by_id" => 901, "body" => "Doplnenie.", "internal" => false)
    assert_equal 603, @tenant.activities.find_by!(triage_external_id: 103).backoffice_external_id
  end

  test "create_activity! adopts an existing article with the same uuid" do
    @tenant.issues.create!(triage_external_id: 42, backoffice_external_id: 500)
    @tenant.users.create!(uuid: ADMIN_UUID, external_id: 901)
    stub_synced_ticket
    stub_backoffice(:post, "ticket_articles", status: 422, body: { error: "This object already exists." })

    @client.create_activity!(42, agent_activity(triage_identifier: 103, uuid: "5b0e6a7c-3f6d-4d1e-8c7a-1d2e3f4a5b6c"))

    assert_equal 601, @tenant.activities.find_by!(triage_external_id: 103).backoffice_external_id
  end

  test "create_activity! re-raises the duplicate error when no article has the uuid" do
    @tenant.issues.create!(triage_external_id: 42, backoffice_external_id: 500)
    @tenant.users.create!(uuid: ADMIN_UUID, external_id: 901)
    stub_synced_ticket
    stub_backoffice(:post, "ticket_articles", status: 422, body: { error: "This object already exists." })

    assert_raises(RuntimeError, match: /This object already exists/) do
      @client.create_activity!(42, agent_activity(triage_identifier: 103, uuid: SecureRandom.uuid))
    end
    assert_nil @tenant.activities.find_by(triage_external_id: 103)
  end

  test "create_activity! raises for an issue the backoffice does not have" do
    error = assert_raises(RuntimeError) { @client.create_activity!(42, agent_activity) }
    assert_equal "Issue not found", error.message
  end

  # Reading tickets and articles

  test "get_issue returns the fields the backoffice owns" do
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket", overrides: { ops_investment: true })

    assert_equal({ ops_state: "in_progress", responsible_subject: { label: "Mesto Malacky", value: 1 }, investment: true }, @client.get_issue(500))
  end

  test "get_activity returns the article with its attachments" do
    stub_synced_ticket
    stub_backoffice(:get, "ticket_attachment/500/600/700", body: "image-bytes")

    activity = @client.get_activity(500, 600)

    assert_equal "text/html", activity[:content_type]
    assert_equal "Lavička na námestí má odlomené dosky.", activity[:body]
    assert_equal [ { filename: "lavicka.jpg", content_type: "image/jpeg", data64: Base64.strict_encode64("image-bytes") } ], activity[:attachments]
  end

  test "get_article returns nil when the ticket does not exist" do
    stub_backoffice(:get, "tickets/500", status: 404, body: zammad_not_found("Ticket"))

    assert_nil @client.get_article(500, 600)
  end

  test "get_article re-raises other Zammad errors" do
    stub_backoffice(:get, "tickets/500", status: 500, body: { error: "Internal Server Error" })

    assert_raises(RuntimeError) { @client.get_article(500, 600) }
  end

  # create_subtask

  test "create_subtask creates the subtask ticket and lists it on the parent's checklist" do
    stub_subtask_creation

    @client.create_subtask(500, 3, 1, "Orezať strom", 7)

    assert_requested :post, backoffice_url("tickets"), query: hash_including({}), body: hash_including(
      "number" => "SUB-0001-1",
      "group_id" => 9,
      "origin" => "subtask",
      "state" => "new",
      "title" => "Orezať strom",
      "origin_by_id" => 3,
      "customer_id" => 3,
      "owner_id" => 7,
      "ops_portal_url" => "http://localhost:3000/podnety/1",
      "address_municipality" => "Bratislava",
      "address_street" => "Hlavná",
      "article" => hash_including(
        "body" => "Orezať strom<br><br><b>Pôvodný podnet:</b><br>Rozbitá lavička na námestí<br>Lavička na námestí má odlomené dosky.",
        "type" => "web",
        "attachments" => [ { "filename" => "lavicka.jpg", "mime-type" => "image/jpeg", "data" => Base64.encode64("image-bytes") } ]
      )
    )
    assert_requested :post, backoffice_url("checklist_items"), body: { "checklist_id" => 20, "text" => "Tiket#SUB-0001-1", "checked" => false }
  end

  test "create_subtask with a due date waits until 8:00 that day" do
    stub_subtask_creation
    due_date = Date.new(2024, 12, 2)

    @client.create_subtask(500, 3, 1, "Orezať strom", 7, due_date)

    assert_requested(:post, backoffice_url("tickets"), query: hash_including({})) do |request|
      body = JSON.parse(request.body)
      body["state"] == "pending reminder" && Time.parse(body["pending_time"]) == due_date.to_time.beginning_of_day + 8.hours
    end
  end

  test "create_subtask can take over the parent's state" do
    stub_subtask_creation

    @client.create_subtask(500, 3, 1, "Orezať strom", 7, use_parent_state: true)

    assert_requested :post, backoffice_url("tickets"), query: hash_including({}), body: hash_including("state" => "open")
  end

  test "create_subtask creates the parent's checklist when it has none" do
    stub_subtask_creation(parent_overrides: { checklist_id: nil })
    stub_backoffice(:post, "checklists", status: 201, body: { id: 21 })
    stub_backoffice(:get, "checklists/21", body: { id: 21, item_ids: [] })

    @client.create_subtask(500, 3, 1, "Orezať strom", 7)

    assert_requested :post, backoffice_url("checklists"), body: { "ticket_id" => 500 }
    assert_requested :post, backoffice_url("checklist_items"), body: hash_including("checklist_id" => 21)
  end

  test "create_subtask does not list a subtask that is already on the checklist" do
    stub_subtask_creation(checklist_item: { id: 30, text: "Tiket#SUB-0001-1", ticket_id: 501 })

    @client.create_subtask(500, 3, 1, "Orezať strom", 7)

    assert_not_requested :post, backoffice_url("checklist_items")
  end

  test "create_subtask adopts an existing subtask ticket with the same number" do
    stub_subtask_creation
    stub_backoffice(:post, "tickets", status: 422, body: { error: "This object already exists." })
    stub_backoffice(:get, "tickets/search", body: [ zammad_fixture("zammad/backoffice_ticket", id: 501, number: "SUB-0001-1") ])

    @client.create_subtask(500, 3, 1, "Orezať strom", 7)

    assert_requested :post, backoffice_url("checklist_items"), body: hash_including("text" => "Tiket#SUB-0001-1")
  end

  test "create_subtask refuses an assignee who is not an agent" do
    stub_backoffice(:get, "users/7", fixture: "zammad/backoffice_agent", overrides: { roles: [ "Customer" ] })

    error = assert_raises(RuntimeError) { @client.create_subtask(500, 3, 1, "Orezať strom", 7) }
    assert_equal "Assignee is not in the subtask group", error.message
    assert_not_requested :post, backoffice_url("tickets"), query: hash_including({})
  end

  test "create_subtask creates the subtask group and gives the tech account access to it" do
    stub_subtask_creation(groups: [ { id: 1, name: "Incoming" } ])
    stub_backoffice(:post, "groups", status: 201, body: { id: 9, name: "Podúlohy" })
    tech_user = { id: 99, firstname: "Aplikácia", lastname: "Odkaz pre starostu", roles: [ "OPS Tech Account" ], groups: {} }
    stub_backoffice(:get, "users", body: [ zammad_fixture("zammad/backoffice_agent"), tech_user ])
    stub_backoffice(:get, "users/99", body: tech_user)
    stub_backoffice(:put, "users/99", body: tech_user)

    @client.create_subtask(500, 3, 1, "Orezať strom", 7)

    assert_requested :post, backoffice_url("groups"), query: hash_including({}), body: { "name" => "Podúlohy" }
    assert_requested :put, backoffice_url("users/99"), query: hash_including({}), body: { "groups" => { "Podúlohy" => "full" } }
    assert_requested :post, backoffice_url("tickets"), query: hash_including({}), body: hash_including("group_id" => 9)
  end

  # update_subtasks

  test "update_subtasks copies the parent's address to its subtasks" do
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket", overrides: { address_street: "Nová", address_house_number: "5" })
    stub_backoffice(:get, "checklists/20", body: { id: 20, item_ids: [ 30, 31 ] })
    stub_backoffice(:get, "checklist_items/30", body: { id: 30, text: "Tiket#SUB-0001-1", ticket_id: 501 })
    stub_backoffice(:get, "checklist_items/31", body: { id: 31, text: "Zavolať občanovi", ticket_id: nil })
    stub_backoffice(:get, "tickets/501", fixture: "zammad/backoffice_ticket", overrides: { id: 501, number: "SUB-0001-1" })
    stub_backoffice(:put, "tickets/501", fixture: "zammad/backoffice_ticket")

    @client.update_subtasks(500)

    assert_requested :put, backoffice_url("tickets/501"), query: hash_including({}), times: 1,
      body: hash_including("address_street" => "Nová", "address_house_number" => "5", "address_municipality" => "Bratislava")
  end

  test "update_subtasks does nothing for a ticket without checklist" do
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket", overrides: { checklist_id: nil })

    @client.update_subtasks(500)

    assert_not_requested :get, %r{/api/v1/checklists/}
  end

  test "update_subtasks ignores a parent ticket that does not exist" do
    stub_backoffice(:get, "tickets/500", status: 404, body: zammad_not_found("Ticket"))

    assert_nil @client.update_subtasks(500)
  end

  # Legacy import: articles from portal activity objects

  test "find_or_create_article_from_activity_object! adds the responsible subject comment to the issue's ticket once" do
    issue = issues(:one)
    comment = Issues::ResponsibleSubjectComment.create!(
      text: "Odstúpené na údržbu zelene.", responsible_subject_author: responsible_subjects(:one),
      triage_external_id: 110, legacy_comment_id: 1, activity: Issues::CommentActivity.new(issue: issue)
    )
    @tenant.issues.create!(triage_external_id: issue.resolution_external_id, backoffice_external_id: 500)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
    stub_backoffice(:post, "ticket_articles", status: 201, body: { id: 601 })

    first = @client.find_or_create_article_from_activity_object!(issue, comment, author_id: 7, internal: true, sender: "Agent")
    second = @client.find_or_create_article_from_activity_object!(issue, comment, author_id: 7, internal: true, sender: "Agent")

    assert_equal 601, first.id
    assert_equal 601, second.id
    assert_requested :post, backoffice_url("ticket_articles"), query: hash_including({}), times: 1, body: hash_including(
      "ticket_id" => 500, "uuid" => comment.uuid, "origin_by_id" => 7, "body" => "Odstúpené na údržbu zelene.",
      "internal" => true, "sender" => "Agent", "type" => "note"
    )
  end

  # Agents, users and groups

  test "create_or_find_agent creates the agent once and remembers it" do
    stub_backoffice(:post, "users", status: 201, body: { id: 7 })
    agent = ResponsibleSubjects::User.new(name: "Ján Referent", email: "referent@malacky.sk")

    assert_equal 7, @client.create_or_find_agent(agent)
    assert_equal 7, @client.create_or_find_agent(agent)

    assert_requested :post, backoffice_url("users"), query: hash_including({}), times: 1, body: {
      "firstname" => "Ján Referent", "login" => "referent@malacky.sk", "email" => "referent@malacky.sk", "roles" => [ "Agent" ], "active" => true
    }
    assert_equal 7, @tenant.users.find_by!(email: "referent@malacky.sk").external_id
  end

  test "create_or_find_agent creates a deleted agent as inactive" do
    stub_backoffice(:post, "users", status: 201, body: { id: 7 })

    @client.create_or_find_agent(ResponsibleSubjects::User.new(name: "Bývalý referent", email: "byvaly@malacky.sk", deleted_at: 1.day.ago))

    assert_requested :post, backoffice_url("users"), query: hash_including({}), body: hash_including("active" => false)
  end

  test "create_or_find_agent uses the anonymous user when there is no agent" do
    assert_equal Connector::ZammadApiClient::ANONYMOUS_USER_ID, @client.create_or_find_agent(nil)
  end

  test "find_or_create_inactive_responsible_subject_user creates an inactive user for the responsible subject" do
    responsible_subject = responsible_subjects(:one)
    responsible_subject.update!(email: "podatelna@staremesto.sk")
    stub_backoffice(:post, "users", status: 201, body: { id: 8 })

    assert_equal 8, @client.find_or_create_inactive_responsible_subject_user(responsible_subject)

    assert_requested :post, backoffice_url("users"), query: hash_including({}),
      body: { "firstname" => "MÚ Staré Mesto", "login" => "ops-rs-#{responsible_subject.id}", "active" => false }
    assert_equal 1, @client.find_or_create_inactive_responsible_subject_user(nil)
  end

  test "add_agent_to_group gives the agent full access to the group" do
    @tenant.users.create!(email: "referent@malacky.sk", external_id: 7)
    stub_backoffice(:get, "users/7", fixture: "zammad/backoffice_agent")
    stub_backoffice(:put, "users/7", fixture: "zammad/backoffice_agent")

    @client.add_agent_to_group(ResponsibleSubjects::User.new(email: "referent@malacky.sk"), "Oddelenie životného prostredia")

    assert_requested :put, backoffice_url("users/7"), query: hash_including({}),
      body: { "groups" => { "Incoming" => "full", "Oddelenie životného prostredia" => "full" } }
  end

  test "find_or_create_imported_article_agent_author puts the agent into the import group" do
    @tenant.users.create!(email: "referent@malacky.sk", external_id: 7)
    stub_backoffice(:get, "users/7", fixture: "zammad/backoffice_agent")
    stub_backoffice(:put, "users/7", fixture: "zammad/backoffice_agent")

    assert_equal 7, @client.find_or_create_imported_article_agent_author(ResponsibleSubjects::User.new(email: "referent@malacky.sk"))

    assert_requested :put, backoffice_url("users/7"), query: hash_including({}),
      body: { "groups" => { "Incoming" => "full", Connector::ZammadApiClient::IMPORT_GROUP => "full" } }
  end

  test "subscribe_ticket mentions the agent on the issue's ticket" do
    issue = issues(:one)
    @tenant.issues.create!(triage_external_id: issue.resolution_external_id, backoffice_external_id: 500)
    @tenant.users.create!(email: "referent@malacky.sk", external_id: 7)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "users/7", fixture: "zammad/backoffice_agent")
    stub_backoffice(:put, "users/7", fixture: "zammad/backoffice_agent")
    mention = stub_backoffice(:post, "mentions", status: 201, body: {})

    @client.subscribe_ticket(ResponsibleSubjects::User.new(email: "referent@malacky.sk"), issue)

    assert_requested mention.with(body: { mentionable_id: 500, mentionable_type: "Ticket" }, headers: { "From" => "7" })
    assert_requested :put, backoffice_url("users/7"), query: hash_including({}),
      body: { "groups" => { "Incoming" => "full", Connector::ZammadApiClient::IMPORT_GROUP => "full" } }
  end

  test "set_ticket_owner_based_on_issue assigns the ticket to the owner" do
    issue = issues(:one)
    @tenant.issues.create!(triage_external_id: issue.resolution_external_id, backoffice_external_id: 500)
    @tenant.users.create!(email: "referent@malacky.sk", external_id: 7)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:put, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "users/7", fixture: "zammad/backoffice_agent")
    stub_backoffice(:put, "users/7", fixture: "zammad/backoffice_agent")

    @client.set_ticket_owner_based_on_issue(issue, owner: ResponsibleSubjects::User.new(email: "referent@malacky.sk"))

    assert_requested :put, backoffice_url("tickets/500"), query: hash_including({}), body: { "owner_id" => 7 }
  end

  test "add_ticket_to_group moves the issue's ticket to the group" do
    issue = issues(:one)
    @tenant.issues.create!(triage_external_id: issue.resolution_external_id, backoffice_external_id: 500)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:put, "tickets/500", fixture: "zammad/backoffice_ticket")

    @client.add_ticket_to_group(issue, "Oddelenie životného prostredia")

    assert_requested :put, backoffice_url("tickets/500"), query: hash_including({}), body: { "group" => "Oddelenie životného prostredia" }
  end

  test "add_user_to_group_read_only gives read access and keeps existing groups" do
    stub_backoffice(:get, "users/7", fixture: "zammad/backoffice_agent")
    stub_backoffice(:put, "users/7", fixture: "zammad/backoffice_agent")

    @client.add_user_to_group_read_only(7, "Oddelenie životného prostredia")

    assert_requested :put, backoffice_url("users/7"), query: hash_including({}),
      body: { "groups" => { "Incoming" => "full", "Oddelenie životného prostredia" => "read" } }
  end

  test "add_ticket_tag tags the issue's ticket" do
    issue = issues(:one)
    @tenant.issues.create!(triage_external_id: issue.resolution_external_id, backoffice_external_id: 500)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    tag = stub_backoffice(:post, "tags/add", status: 201, body: true)

    @client.add_ticket_tag(issue, "chodníky")

    assert_requested tag.with(body: { item: "chodníky", o_id: 500, object: "Ticket" })
  end

  test "add_ticket_tag raises when Zammad does not create the tag" do
    issue = issues(:one)
    @tenant.issues.create!(triage_external_id: issue.resolution_external_id, backoffice_external_id: 500)
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:post, "tags/add", status: 200, body: true)

    error = assert_raises(RuntimeError) { @client.add_ticket_tag(issue, "chodníky") }
    assert_equal "Tag not successfully added!", error.message
  end

  test "update_customer renames the backoffice customer" do
    user = users(:one)
    @tenant.users.create!(uuid: user.uuid, external_id: 900)
    stub_backoffice(:get, "users/900", fixture: "zammad/backoffice_agent", overrides: { id: 900 })
    stub_backoffice(:put, "users/900", fixture: "zammad/backoffice_agent")

    @client.update_customer(user)

    assert_requested :put, backoffice_url("users/900"), query: hash_including({}), body: { "firstname" => "Jozef Mokry" }
  end

  test "update_customer ignores users the backoffice does not know" do
    assert_equal false, @client.update_customer(users(:one))
  end

  test "check_import_mode! raises when import mode is off" do
    stub_backoffice(:get, "settings", body: [ { name: "import_mode", state_current: { value: false } } ])

    error = assert_raises(RuntimeError) { @client.check_import_mode! }
    assert_equal "Import mode OFF", error.message
  end

  test "check_import_mode! passes when import mode is on" do
    stub_backoffice(:get, "settings", fixture: "zammad/settings")

    assert_nothing_raised { @client.check_import_mode! }
  end

  test "raw API requests re-raise connection failures" do
    stub_request(:get, backoffice_url("settings")).to_timeout

    assert_raises(Faraday::Error) { @client.check_import_mode! }
  end

  private

  def stub_backoffice(method, path, **options)
    stub_zammad(method, path, url: @tenant.backoffice_url, **options)
  end

  def backoffice_url(path)
    zammad_url(path, url: @tenant.backoffice_url)
  end

  # Portal customers get backoffice id 900, the OPS admin author 901.
  def stub_backoffice_user_creation
    stub_request(:post, backoffice_url("users")).with(query: hash_including({})).to_return do |request|
      id = JSON.parse(request.body)["login"] == CITIZEN_UUID ? 900 : 901
      { status: 201, body: { id: id }.to_json, headers: { "Content-Type" => "application/json" } }
    end
  end

  def stub_synced_ticket
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket")
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
  end

  def stub_subtask_creation(parent_overrides: {}, groups: [ { id: 1, name: "Incoming" }, { id: 9, name: "Podúlohy" } ],
                            checklist_item: { id: 30, text: "Zavolať občanovi", ticket_id: nil })
    stub_backoffice(:get, "users/7", fixture: "zammad/backoffice_agent")
    stub_backoffice(:get, "users/3", fixture: "zammad/backoffice_agent", overrides: { id: 3, login: "veduci@malacky.sk" })
    stub_backoffice(:get, "tickets/500", fixture: "zammad/backoffice_ticket", overrides: parent_overrides)
    stub_backoffice(:get, "ticket_articles/by_ticket/500", fixture: "zammad/backoffice_ticket_articles")
    stub_backoffice(:get, "ticket_attachment/500/600/700", body: "image-bytes")
    stub_backoffice(:get, "groups", body: groups)
    stub_backoffice(:post, "tickets", status: 201, fixture: "zammad/backoffice_ticket", overrides: { id: 501, number: "SUB-0001-1" })
    stub_backoffice(:get, "checklists/20", body: { id: 20, item_ids: [ 30 ] })
    stub_backoffice(:get, "checklist_items/30", body: checklist_item)
    stub_backoffice(:post, "checklist_items", status: 201, body: { id: 31 })
  end

  # Mirrors app/views/api/v1/issues/show.json.jbuilder as parsed by Connector::OpsApiClient.
  def issue_payload(**overrides)
    {
      "triage_identifier" => 42,
      "ops_issue_identifier" => 1,
      "ops_state" => "sent_to_responsible",
      "title" => "Rozbitá lavička na námestí",
      "responsible_subject" => { "label" => "Mesto Malacky", "value" => 1 },
      "responsible_subject_changed_at" => nil,
      "author" => { "firstname" => "Jozef", "lastname" => "Mokry", "uuid" => CITIZEN_UUID },
      "issue_type" => "issue",
      "category" => "Zeleň a životné prostredie",
      "subcategory" => "Strom",
      "subtype" => nil,
      "address_municipality" => "Bratislava::Staré Mesto",
      "address_postcode" => "81101",
      "address_street" => "Hlavná",
      "address_house_number" => "1",
      "likes_count" => 3,
      "address_lat" => 48.1486,
      "address_lon" => 17.1077,
      "portal_url" => "http://localhost:3000/podnety/1",
      "created_at" => "2024-11-05T09:59:21.000Z",
      "updated_at" => "2024-11-06T10:00:00.000Z",
      "activities" => [ citizen_activity, agent_activity ]
    }.merge(overrides.stringify_keys)
  end

  def citizen_activity(author: { "firstname" => "Jozef", "lastname" => "Mokry", "uuid" => CITIZEN_UUID })
    {
      "triage_identifier" => 101,
      "activity_type" => "user_portal_comment",
      "uuid" => "0c8f5b8e-1c1d-4a4e-9a57-8c6f0f7b6a01",
      "author" => author,
      "content_type" => "text/html",
      "body" => "Lavička na námestí má odlomené dosky.",
      "created_at" => "2024-11-05T09:59:21.000Z",
      "updated_at" => "2024-11-05T09:59:21.000Z",
      "attachments" => [ { "triage_identifier" => 501, "filename" => "lavicka.jpg", "content_type" => "image/jpeg", "data64" => "aW1hZ2U=" } ]
    }
  end

  def agent_activity(**overrides)
    {
      "triage_identifier" => 102,
      "activity_type" => "agent_portal_and_backoffice_comment",
      "uuid" => "5b0e6a7c-3f6d-4d1e-8c7a-1d2e3f4a5b6c",
      "author" => ZammadApiClient::DEFAULT_OPS_ADMIN_USER.stringify_keys,
      "content_type" => "text/html",
      "body" => "Podnet sme odstúpili.",
      "created_at" => "2024-11-06T09:00:00.000Z",
      "updated_at" => "2024-11-06T09:00:00.000Z",
      "attachments" => []
    }.merge(overrides.stringify_keys)
  end
end
