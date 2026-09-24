module Connector
  class ZammadApiClient
    attr :client

    # TODO
    ANONYMOUS_USER_ID = 1
    DEFAULT_GROUP = "Incoming"
    IMPORT_GROUP = "Stará verzia Odkaz pre starostu"
    DEFAULT_STATE = "new"
    DEFAULT_SENDER = "Customer"
    OPS_ORIGIN = "ops"
    SUBTASK_ORIGIN = "subtask"
    SUBTASK_ARTICLE_CONTENT_TYPE = "text/html"
    DEFAULT_SUBTASK_GROUP = "Podúlohy"
    DEFAULT_ARTICLE_CONTENT_TYPE = "text/html"
    DEFAULT_ARTICLE_TYPE = "note"
    DEFAULT_FIRST_ARTICLE_TYPE = "web"

    def initialize(tenant)
      @token = tenant.backoffice_api_token
      @url = tenant.backoffice_url
      @tenant = tenant
      @client = ZammadAPI::Client.new(url: @url, http_token: @token)
    end

    def create_issue!(issue, state: DEFAULT_STATE, group: DEFAULT_GROUP)
      ticket = find_or_create_ticket!(issue, state: state, group: group)

      issue["activities"][1..-1].each do |activity|
        find_or_create_article!(ticket, activity)
      end
    end

    def update_issue!(issue_id, issue_data)
      issue = @tenant.issues.find_by(triage_external_id: issue_id)
      return create_issue!(issue_data) unless issue

      ticket = @client.ticket.find(issue.backoffice_external_id)
      for key, value in issue_data
        case key
        when "ops_state"
          ticket.ops_state = value
        when "responsible_subject"
          ticket.ops_responsible_subject = value
        when "responsible_subject_changed_at"
          ticket.ops_responsible_subject_changed_at = value
        when "likes_count"
          ticket.ops_likes_count = value
        when "category"
          ticket.ops_category = value
        when "subcategory"
          ticket.ops_subcategory = value
        when "subtype"
          ticket.ops_subtype = value
        when "address_municipality"
          ticket.address_municipality = value&.split("::").first
          ticket.address_municipality_district = value&.split("::").second || ""
        when "address_street"
          ticket.address_street = value
        when "address_house_number"
          ticket.address_house_number = value
        when "address_postcode"
          ticket.address_postcode = value
        when "address_lat"
          ticket.address_lat = value
        when "address_lon"
          ticket.address_lon = value
        end
      end
      ticket.save
    end

    def create_activity!(issue_id, activity)
      issue = @tenant.issues.find_by(triage_external_id: issue_id)
      raise "Issue not found" unless issue

      ticket = @client.ticket.find(issue.backoffice_external_id)
      find_or_create_article!(ticket, activity)
    end

    def get_issue(issue_id)
      ticket = @client.ticket.find(issue_id)

      {
        ops_state: ticket.ops_state,
        responsible_subject: ticket.ops_responsible_subject,
        investment: ticket.ops_investment
      }
    end

    def create_subtask(parent_ticket_id, author_id, number, title, user_id, due_date = nil, use_parent_state: false)
      assignee = @client.user.find(user_id)
      raise "Assignee is not in the subtask group" unless assignee.roles.include?("Agent")

      parent_ticket = @client.ticket.find(parent_ticket_id)
      raise "Parent ticket not found" unless parent_ticket

      author = @client.user.find(author_id)
      issue_number = parent_ticket.number.gsub("OPS-", "SUB-").gsub("M-", "SUB-") + "-#{number}"
      group = find_or_create_group(DEFAULT_SUBTASK_GROUP)

      subtask_state = if use_parent_state
        parent_ticket.state
      else
        DEFAULT_STATE
      end

      tmp_body = {
        number: issue_number,
        group_id: group.id,
        origin: SUBTASK_ORIGIN,
        state: subtask_state,
        title: title,
        origin_by_id: author.id,
        customer_id: author.id,
        owner_id: assignee.id,
        ops_portal_url: parent_ticket.ops_portal_url,
        address_municipality: parent_ticket.address_municipality,
        address_municipality_district: parent_ticket.address_municipality_district,
        address_street: parent_ticket.address_street,
        address_house_number: parent_ticket.address_house_number,
        address_postcode: parent_ticket.address_postcode,
        address_lat: parent_ticket.address_lat,
        address_lon: parent_ticket.address_lon,
        article: {
          origin_by_id: author.id,
          content_type: SUBTASK_ARTICLE_CONTENT_TYPE,
          body: "#{title}<br><br><b>Pôvodný podnet:</b><br>#{parent_ticket.title}<br>#{parent_ticket.articles.first.body}",
          type: DEFAULT_FIRST_ARTICLE_TYPE,
          sender: DEFAULT_SENDER,
          attachments: parent_ticket.articles.map(&:attachments).flatten.map do |attachment|
            {
              "filename" => attachment.filename,
              "mime-type" => attachment.preferences.dig(:"Mime-Type") || attachment.preferences.dig(:"Content-Type"),
              "data" => Base64.encode64(attachment.download)
            }
          end
        }
      }

      if due_date
        tmp_body[:pending_time] = due_date.to_time.beginning_of_day + 8.hours
        tmp_body[:state] = "pending reminder"
      end

      subtask_ticket = nil
      begin
        subtask_ticket = @client.ticket.create(tmp_body)
      rescue RuntimeError => e
        raise e unless /.*This object already exists/.match?(e.message) || e.message.include?("Can't save object")
        search_result = @client.ticket.search(query: "\"#{issue_number}\"").select { |r| r.number == issue_number }
        raise e unless search_result.count == 1
        subtask_ticket = search_result.first
      end

      raise "Subtask ticket not created" unless subtask_ticket

      parent_ticket_json = raw_api_request(:get, "tickets/#{parent_ticket_id}").first
      raise "Parent ticket not found" unless parent_ticket_json

      checklist_id = parent_ticket_json["checklist_id"]
      unless checklist_id
        r = raw_api_request(:post, "checklists", params: { ticket_id: parent_ticket_id })
        raise "Checklist not created" unless r.second < 300

        checklist_id = r.first["id"]
      end

      checklist = raw_api_request(:get, "checklists/#{checklist_id}").first
      raise "Checklist not found" unless checklist

      checklist_items = checklist["item_ids"].map do |item_id|
        raw_api_request(:get, "checklist_items/#{item_id}").first
      end

      unless checklist_items.any? { |i| i["ticket_id"] == subtask_ticket.id }
        r = raw_api_request(:post, "checklist_items", params: { checklist_id: checklist_id, text: "Tiket##{subtask_ticket.number}", checked: false })
        raise "Checklist item not created" unless r.second < 300
      end
    end

    def update_subtasks(parent_ticket_id)
      parent_ticket = @client.ticket.find(parent_ticket_id)
      raise "Parent ticket not found" unless parent_ticket

      parent_ticket_json = raw_api_request(:get, "tickets/#{parent_ticket_id}").first
      raise "Parent ticket not found" unless parent_ticket_json

      checklist_id = parent_ticket_json["checklist_id"]
      return unless checklist_id

      checklist = raw_api_request(:get, "checklists/#{checklist_id}").first
      raise "Checklist not found" unless checklist

      checklist["item_ids"].each do |item_id|
        item = raw_api_request(:get, "checklist_items/#{item_id}").first
        next unless item["ticket_id"]

        subtask_ticket = @client.ticket.find(item["ticket_id"])
        next unless subtask_ticket

        subtask_ticket.address_municipality = parent_ticket.address_municipality
        subtask_ticket.address_municipality_district = parent_ticket.address_municipality_district
        subtask_ticket.address_street = parent_ticket.address_street
        subtask_ticket.address_house_number = parent_ticket.address_house_number
        subtask_ticket.address_postcode = parent_ticket.address_postcode
        subtask_ticket.address_lat = parent_ticket.address_lat
        subtask_ticket.address_lon = parent_ticket.address_lon
        subtask_ticket.save
      end
    rescue RuntimeError => e
      raise e unless e.message.include? "Couldn't find Ticket with"
      nil
    end

    def get_article(ticket_id, article_id)
      ticket = @client.ticket.find(ticket_id)
      ticket.articles.find { |a| article_id == a.id.to_i }
    rescue RuntimeError => e
      raise e unless e.message.include? "Couldn't find Ticket with"
      nil
    end

    def get_activity(ticket_id, activity_id)
      article = get_article(ticket_id, activity_id)

      {
        content_type: article.content_type,
        body: article.body,
        attachments: article.attachments.map do |attachment|
          {
            filename: attachment.filename,
            content_type: attachment.preferences.dig(:"Mime-Type") || attachment.preferences.dig(:"Content-Type"),
            data64: Base64.strict_encode64(attachment.download)
          }
        end
      }
    end

    def find_or_create_article_from_activity_object!(issue, activity_object, author_id: nil, internal:, sender:)
      ticket = find_ticket_for_issue!(issue)

      article = @tenant.activities.find_by(triage_external_id: activity_object.triage_external_id)
      return @client.ticket.find(ticket.id).articles.find { |a| article.backoffice_external_id == a.id } if article

      begin
        new_article = ticket.article(
          uuid: activity_object.uuid,
          origin_by_id: author_id,
          content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
          body: activity_object.backoffice_activity_body,
          type: DEFAULT_ARTICLE_TYPE,
          internal: internal,
          triage_created_at: activity_object.created_at,
          attachments: activity_object.attachments.map do |attachment|
            {
              "filename" => attachment.filename,
              "mime-type" => attachment.content_type,
              "data" => Base64.encode64(attachment.blob.download)
            }
          end,
          sender: sender,
          created_at: activity_object.created_at
        )

        # TODO custom error
        raise unless new_article.id
      rescue RuntimeError => e
        raise e unless /.*This object already exists/.match?(e.message)

        search_result = @client.ticket.find(ticket.id).articles.select { |a| a.uuid == activity_object.uuid }

        raise e unless search_result.count == 1

        new_article = search_result.first
      end

      @tenant.activities.create!(triage_external_id: activity_object.triage_external_id, backoffice_external_id: new_article.id)
      new_article
    end

    def find_or_create_article_from_legacy_data!(legacy_data, tenant_issue, uuid:, sender:)
      ticket = @client.ticket.find(tenant_issue.backoffice_external_id)

      article = @tenant.activities.find_by(legacy_id: legacy_data.id)
      return ticket.articles.find { |a| article.backoffice_external_id == a.id } if article

      begin
        new_article = ticket.article(
          uuid: uuid,
          origin_by_id: create_or_find_agent(legacy_data.author),
          content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
          body: legacy_data.body,
          type: DEFAULT_ARTICLE_TYPE,
          internal: legacy_data.internal,
          attachments: legacy_data.attachments.map do |attachment|
            {
              "filename" => attachment.filename,
              "mime-type" => attachment.mimetype,
              "data" => Base64.encode64(attachment.content)
            }
          end,
          sender: sender,
          created_at: legacy_data.created_at
        )

        raise unless new_article.id
      rescue RuntimeError => e
        raise e unless /.*This object already exists/.match?(e.message)

        search_result = ticket.articles.select { |a| a.uuid == uuid }

        raise e unless search_result.count == 1

        new_article = search_result.first
      end

      @tenant.activities.create!(legacy_id: legacy_data.id, backoffice_external_id: new_article.id)
      new_article
    end

    def find_or_create_ticket_from_legacy_data!(legacy_data, state:, group:)
      tenant_issue = @tenant.issues.find_by(legacy_id: legacy_data.id)
      return @client.ticket.find(tenant_issue.backoffice_external_id) if tenant_issue

      issue_number = "M-#{legacy_data.id.to_s.rjust(4, '0')}"

      tmp_body = {
        number: issue_number,
        state: state,
        group: group,
        title: legacy_data.title,
        ops_responsible_subject: {
          "label"=> legacy_data.responsible_subject&.subject_name,
          "value"=> legacy_data.responsible_subject&.id
        },
        ops_category: legacy_data.category&.name,
        ops_subcategory: legacy_data.subcategory&.name,
        ops_subtype: legacy_data.subtype&.name,
        address_municipality: legacy_data.municipality&.name,
        address_municipality_district: legacy_data.municipality_district&.name || "",
        address_street: legacy_data.address_street,
        address_lat: legacy_data.latitude,
        address_lon: legacy_data.longitude,
        created_at: legacy_data.created_at,
        origin_by_id: create_or_find_agent(legacy_data.author),
        customer_id: create_or_find_agent(legacy_data.author),
        article: {
          body: legacy_data.description.presence || "(bez popisu)",
          type: DEFAULT_FIRST_ARTICLE_TYPE,
          internal: legacy_data.internal,
          attachments: legacy_data.attachments.map do |attachment|
            {
              "filename" => attachment.filename,
              "mime-type" => attachment.mimetype,
              "data" => Base64.encode64(attachment.content.read)
            }
          end,
          created_at: legacy_data.created_at
        },
        tags: legacy_data.tags
      }

      begin
        new_ticket = @client.ticket.create(tmp_body)
        # TODO custom error
        raise unless new_ticket.id
      rescue RuntimeError => e
        raise e unless /.*This object already exists/.match?(e.message)

        search_result = @client.ticket.search(query: "\"#{issue_number}\"").select { |r| r.number == issue_number }

        raise e if search_result.count == 0

        raise "Found multiple matches for ticket!" unless search_result.count == 1

        new_ticket = search_result.first
      end

      @tenant.issues.create!(legacy_id: legacy_data.id, backoffice_external_id: new_ticket.id)

      # set_ticket_owner(new_ticket, owner: legacy_data.owner)
      # set_ticket_subscribers_from_legacy_data(new_ticket, legacy_data)

      new_ticket
    end

    def set_ticket_subscribers_from_legacy_data(ticket, legacy_data)
      legacy_data.subscribers.each do |subscriber|
        subscriber_id = create_or_find_agent(subscriber)
        mention_agent_in_ticket(subscriber_id, ticket)
      end
    end

    def set_ticket_owner_based_on_issue(issue, owner: issue.backoffice_owner)
      ticket = find_ticket_for_issue!(issue)
      set_ticket_owner(ticket, owner: owner)
    end

    def set_ticket_owner_based_on_tenant_issue(tenant_issue, owner:)
      ticket = @client.ticket.find(tenant_issue.backoffice_external_id)
      set_ticket_owner(ticket, owner: owner)
    end

    def set_ticket_owner(ticket, owner:)
      user_id = create_or_find_agent(owner)
      add_user_to_group(user_id, IMPORT_GROUP)

      ticket.owner_id = user_id
      ticket.save
    end

    def add_agent_to_group(owner, group_name)
      user_id = create_or_find_agent(owner)
      add_user_to_group(user_id, group_name)
    end

    def add_ticket_tag(issue, tag_name)
      ticket = find_ticket_for_issue!(issue)

      _, response_status = raw_api_request(
        :post,
        "tags/add",
        params: {
          item: tag_name,
          o_id: ticket.id,
          object: "Ticket"
        }
      )

      raise "Tag not successfully added!" unless response_status == 201
    end

    def find_or_create_imported_article_agent_author(user)
      user_id = create_or_find_agent(user)
      add_user_to_group(user_id, IMPORT_GROUP)

      user_id
    end

    def find_or_create_inactive_responsible_subject_user(responsible_subject)
      return ANONYMOUS_USER_ID unless responsible_subject

      user = @tenant.users.find_or_initialize_by(email: responsible_subject.email)
      return user.external_id unless user.new_record?

      zammad_identifier = find_or_create_user!(
        firstname: responsible_subject.subject_name,
        login: "ops-rs-#{responsible_subject.id}",
        active: false
      ).id

      user.update(firstname: responsible_subject.name, external_id: zammad_identifier)

      zammad_identifier
    end

    def subscribe_ticket(agent, issue)
      ticket = find_ticket_for_issue!(issue)

      agent_id = create_or_find_agent(agent)

      raise "Agent not found in backoffice!" unless agent_id

      mention_agent_in_ticket(agent_id, ticket)
    end

    def mention_agent_in_ticket(agent_id, ticket)
      add_user_to_group(agent_id, IMPORT_GROUP)

      _, response_status = raw_api_request(
        :post,
        "mentions",
        params: {
          mentionable_id: ticket.id,
          mentionable_type: "Ticket"
        },
        headers: {
          "From": agent_id.to_s
        }
      )

      raise "Ticket subscription not successful!" unless response_status == 201
    end

    def check_import_mode!(force: false)
      return if !force && @last_import_mode_check && @last_import_mode_check > 1.minute.ago

      response_body, _ = raw_api_request(:get, "settings")
      import_mode_on = response_body.select { |attribute| attribute["name"] == "import_mode" }.first["state_current"]["value"]

      raise "Import mode OFF" unless import_mode_on

      @last_import_mode_check = Time.now
    end

    def find_or_create_group(group_name)
      group = @client.group.all.select { |g| g.name == group_name }&.first

      return group if group

      group = @client.group.create(name: group_name)
      # add tech user to the new group
      add_user_to_group(get_tech_user_id, group_name)
      group
    end

    def add_ticket_to_group(issue, group_name)
      ticket = find_ticket_for_issue!(issue)

      ticket.group = group_name
      ticket.save
    end

    def add_manual_ticket_to_group(tenant_issue, group_name)
      ticket = @client.ticket.find(tenant_issue.backoffice_external_id)

      ticket.group = group_name
      ticket.save
    end

    def add_user_to_group_read_only(user_identifier, group_name)
      user = get_user(user_identifier)
      user_groups = user.groups
      user_groups[group_name] = "read"
      user.groups = user_groups

      user.save
    end

    def create_or_find_agent(author)
      return ANONYMOUS_USER_ID unless author

      user = @tenant.users.find_or_initialize_by(email: author.email)
      return user.external_id unless user.new_record?

      zammad_identifier = find_or_create_user!(
        firstname: author.name,
        login: author.email,
        email: author.email,
        roles: [ "Agent" ],
        active: author.deleted_at.nil?
      ).id

      user.update(firstname: author.name, external_id: zammad_identifier)

      zammad_identifier
    end

    def update_customer(user)
      tenant_user = @tenant.users.find_by(uuid: user["uuid"])
      return false unless tenant_user

      result = get_user(tenant_user.external_id)
      return false unless result

      result.firstname = user.display_name
      result.lastname = "" if user.anonymous?
      result.save
    end

    private

    def create_or_find_customer(author)
      return ANONYMOUS_USER_ID unless author

      user = @tenant.users.find_or_initialize_by(uuid: author["uuid"])
      return user.external_id unless user.new_record?

      zammad_identifier = find_or_create_user!(
        firstname: author["firstname"],
        lastname: author["lastname"],
        login: author["uuid"],
        roles: [ "OPS User" ],
      ).id

      user.update(firstname: author["firstname"], lastname: author["lastname"], external_id: zammad_identifier)

      zammad_identifier
    end

    def find_zammad_user(query)
      # searches user by email, firstname, lastname and login
      @client.user.search(query: query).first
    end

    def find_or_create_user!(user_params)
      begin
        zammad_user = @client.user.create(user_params)
        zammad_user
      rescue RuntimeError => e
        raise e unless e.message.include? "is already used for another user."

        zammad_user = find_zammad_user(user_params["email"] || user_params["login"])
        raise "Can't find nor create zammad user with email: #{user_params["email"]}" unless zammad_user
        zammad_user
      end
    end

    def get_tech_user_id
      @client.user.all.select { |u| u.firstname == "Aplikácia" && u.lastname == "Odkaz pre starostu" && "OPS Tech Account".in?(u.roles) }.first.id
    end

    def add_user_to_group(user_identifier, group_name)
      user = get_user(user_identifier)
      user_groups = user.groups
      user_groups[group_name] = "full"
      user.groups = user_groups

      user.save
    end

    def find_ticket_for_issue!(issue)
      ticket = @tenant.issues.find_by(triage_external_id: issue.resolution_external_id)
      @client.ticket.find(ticket.backoffice_external_id)
    end

    def find_or_create_ticket!(issue, state:, group:)
      ticket = @tenant.issues.find_by(triage_external_id: issue["triage_identifier"])
      activity = @tenant.activities.find_by(triage_external_id: issue["triage_identifier"])
      return @client.ticket.find(ticket.backoffice_external_id) if ticket && activity

      issue_number = "OPS-#{issue['ops_issue_identifier'].to_s.rjust(4, '0')}"

      article = issue["activities"].first
      tmp_body = {
        number: issue_number,
        state: state,
        group: group,
        origin: OPS_ORIGIN,
        title: issue["title"],
        ops_state: issue["ops_state"],
        origin_by_id: create_or_find_customer(issue["author"]),
        customer_id: create_or_find_customer(issue["author"]),
        ops_issue_type: issue["issue_type"],
        ops_issue_identifier: issue["ops_issue_identifier"],
        ops_responsible_subject: issue["responsible_subject"],
        ops_category: issue["category"],
        ops_subcategory: issue["subcategory"],
        ops_subtype: issue["subtype"],
        address_municipality: issue["address_municipality"].split("::").first,
        address_municipality_district: issue["address_municipality"].split("::").second || "",
        address_street: issue["address_street"],
        address_house_number: issue["address_house_number"],
        address_postcode: issue["address_postcode"],
        address_lat: issue["address_lat"],
        address_lon: issue["address_lon"],
        ops_responsible_subject_changed_at: issue["responsible_subject_changed_at"],
        ops_likes_count: issue["likes_count"],
        ops_portal_url: issue["portal_url"],
        created_at: issue["created_at"],
        updated_at: issue["updated_at"],
        article: {
          origin_by_id: create_or_find_customer(article["author"]),
          content_type: article["content_type"],
          body: article["body"],
          type: DEFAULT_FIRST_ARTICLE_TYPE,
          triage_created_at: article["created_at"],
          attachments: article["attachments"].map do |attachment|
            {
              "filename" => attachment["filename"],
              "mime-type" => attachment["content_type"],
              "data" => attachment["data64"]
            }
          end,
          sender: DEFAULT_SENDER,
          created_at: issue["created_at"]
        }
      }

      begin
        new_ticket = @client.ticket.create(tmp_body)
        # TODO custom error
        raise unless new_ticket.id
      rescue RuntimeError => e
        raise e unless /.*This object already exists/.match?(e.message)

        search_result = @client.ticket.search(query: "\"#{issue_number}\"").select { |r| r.number == issue_number }

        raise e if search_result.count == 0

        raise "Found multiple matches for ticket!" unless search_result.count == 1

        new_ticket = search_result.first
      end

      @tenant.issues.create!(triage_external_id: issue["triage_identifier"], backoffice_external_id: new_ticket.id)
      @tenant.activities.create!(triage_external_id: issue["triage_identifier"], backoffice_external_id: new_ticket.articles.first.id)
      new_ticket
    end

    def find_or_create_article!(ticket, activity, sender: DEFAULT_SENDER)
      article = @tenant.activities.find_by(triage_external_id: activity["triage_identifier"])
      return @client.ticket.find(ticket.id).articles.find { |a| article.backoffice_external_id == a.id } if article

      begin
        new_article = ticket.article(
          uuid: activity["uuid"],
          origin_by_id: create_or_find_customer(activity["author"]),
          content_type: activity["content_type"],
          body: activity["body"],
          type: DEFAULT_ARTICLE_TYPE,
          internal: false,
          triage_created_at: activity["created_at"],
          attachments: activity["attachments"].map do |attachment|
            {
              "filename" => attachment["filename"],
              "mime-type" => attachment["content_type"],
              "data" => attachment["data64"]
            }
          end,
          sender: sender,
          created_at: activity["created_at"]
        )

        # TODO custom error
        raise unless new_article.id
      rescue RuntimeError => e
        raise e unless /.*This object already exists/.match?(e.message)

        search_result = @client.ticket.find(ticket.id).articles.select { |a| a.uuid == activity["uuid"] }

        raise e unless search_result.count == 1

        new_article = search_result.first
      end

      @tenant.activities.create!(triage_external_id: activity["triage_identifier"], backoffice_external_id: new_article.id)
      new_article
    end

    def get_user(identifier)
      @client.user.find identifier
    end

    def raw_api_request(method, endpoint, params: {}, headers: {})
      url = File.join(@url, "api/v1/", endpoint)
      connection = Faraday.new(url: url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter :net_http
      end

      response = connection.send(method) do |req|
        req.headers.merge!(headers)
        req.headers["Authorization"] = "Token token=#{@token}"
        req.body = params.to_json unless params.empty?
      end
    rescue StandardError => error
      raise error.response if error.respond_to?(:response) && error.response
      raise error
    else
      raise "Request failed with status #{response.status}" unless response.status < 400

      [ response.body, response.status ]
    end
  end
end
