class ZammadApiClient
  attr :client

  DEFAULT_SENDER = "Customer"
  DEFAULT_GROUP = "Incoming"
  DEFAULT_PROCESS_TYPE = "portal_issue_triage"
  DEFAULT_ARTICLE_TYPE = "web"
  DEFAULT_ORIGIN = "portal"
  DEFAULT_ARTICLE_CONTENT_TYPE = "text/html"
  USERS_PER_PAGE = 1000
  # TODO: consider seeding this value
  DEFAULT_OPS_ADMIN_USER = {
    firstname: "Dobrovoľník Odkazu pre starostu",
    lastname: "",
    uuid: "11111111-1111-1111-1111-111111111111"
  }
  RESPONSIBLE_SUBJECT_ARTICLE_TAG = TriageZammadEnvironment::RESPONSIBLE_SUBJECT_ARTICLE_TAG
  OPS_PORTAL_ARTICLE_TAG = TriageZammadEnvironment::OPS_PORTAL_ARTICLE_TAG
  MARKED_AS_RESOLVED_TAGS = [ "[[vyriesene]]", "[[vyriešené]]", "[[vyrieseny]]", "[[vyriešený]]" ]
  REFERRED_TAGS = [ "[[odstupene]]", "[[odstúpené]]", "[[odstupeny]]", "[[odstúpený]]" ]
  AUTOMATED_EMAIL_SENDER_PATTERNS = [
    /\b(?:auto(?:mated)?[-_. ]?reply|bounce|do[-_. ]?not[-_. ]?reply|mailer-daemon|no[-_. ]?reply|postmaster)@/i
  ]
  AUTOMATED_EMAIL_SUBJECT_PATTERNS = [
    /\b(?:automatic|auto(?:mated)?)\s*reply\b/i,
    /\b(?:out of (?:the )?office|away from (?:the )?office)\b/i,
    /\b(?:delivery (?:has )?(?:failed|failure|status)|undeliverable|mail delivery failed)\b/i
  ]

  ATTACHMENTS_UPDATE_ARTICLE_BODY = "Aktualizované prílohy"
  ATTACHMENTS_UPDATE_ARTICLE_TYPE = "note"

  DEFAULT_ALLOWED_ARTICLE_TYPES = [
    :unknown_user_portal_comment,             # unknown user comment visible on portal
    :user_portal_comment,                     # user comment visible on portal
    :agent_portal_comment,                    # agent comment visible on portal
    :agent_portal_and_backoffice_comment,     # agent comment visible on portal, triage and backoffice
    :responsible_subject_portal_and_backoffice_comment,      # responsible subject comment visible on portal, triage and backoffice
    :agent_backoffice_comment                 # agent comment visible in triage and backoffice
    # :user_private_comment,                  # user comment visible on portal in triage_process
    # :agent_private_comment,                 # agent comment visible on portal in triage_process
    # :system_note,                           # system note
  ]

  def initialize(url:, http_token:)
    @url = url
    @http_token = http_token
    @client = ZammadAPI::Client.new(url: url, http_token: http_token)
  end

  def get_ticket(ticket_id, expand: false, allowed_article_types: DEFAULT_ALLOWED_ARTICLE_TYPES, responsible_subject: nil)
    begin
      ticket = @client.ticket.find(ticket_id)
    rescue => e
      raise e unless e.message.include?("Couldn't find Ticket with")
      return
    end

    return unless ticket.origin == "portal"

    case ticket.process_type
    when "portal_issue_triage", "portal_issue_resolution"
      result = build_issue_ticket_response(ticket)
      return unless result.present?

      if ticket.issue_type == "praise"
        result.merge({
          activities: [
            {
              article_type: :user_portal_comment,
              author: result[:author],
              author_response: result[:author_response],
              triage_identifier: ticket.articles.first.id,
              content_type: ticket.articles.first.content_type,
              body: result[:description],
              created_at: result[:created_at],
              updated_at: result[:updated_at],
              attachments: ticket.articles.first.attachments.map do |attachment|
                {
                  triage_identifier: attachment.id,
                  filename: attachment.filename,
                  content_type: attachment.preferences.dig(:"Mime-Type") || attachment.preferences.dig(:"Content-Type"),
                  data64: Base64.strict_encode64(attachment.download)
                }
              end
            }
          ]
        })

      else
        return result unless expand

        result.merge({
          activities: [ build_article_response(ticket, ticket.articles.first, allowed_article_types: allowed_article_types, first_article: true) ] +
            ticket.articles[1..].map { |article|
              build_article_response(
                ticket,
                article,
                allowed_article_types: allowed_article_types,
                responsible_subject: responsible_subject
              )
            }.compact
        })
      end
    when "portal_issue_verification"
      {
        triage_identifier: ticket.id,
        triage_group: ticket.group,
        ops_state_key: ticket.ops_state,
        origin: ticket.origin,
        process_type: ticket.process_type,
        title: ticket.title,
        description: ticket.description,
        likes_count: ticket.likes_count,
        portal_url: ticket.portal_url,
        issue_resolved: ticket.issue_resolved,
        created_at: ticket.created_at,
        updated_at: ticket.updated_at
      }
    else
      raise "Process type not yet supported: #{ticket.process_type}"
    end
  end

  def create_ticket_from_issue!(issue, issue_number:, process_type: DEFAULT_PROCESS_TYPE, state: nil, group: DEFAULT_GROUP, sender: DEFAULT_SENDER, owner_id: nil)
    ops_state = issue.state&.key
    if issue.issue_type == "praise" && ops_state == "resolved_private"
      ops_state = "unresolved"
    end

    ticket = @client.ticket.create(
      number: issue_number,
      ops_issue_identifier: issue.id,
      process_type: process_type,
      issue_type: issue.issue_type,
      title: issue.title.presence || "Bez názvu",
      description: issue.description,
      group: group,
      customer_id: issue.author.external_id,
      origin_by_id: issue.author.external_id,
      address_state: issue.address_region, # TODO rename this?
      address_county: issue.address_district, # TODO rename this?
      address_municipality: build_ticket_municipality(issue),
      address_postcode: issue.address_postcode,
      address_street: issue.address_street,
      address_house_number: issue.address_house_number,
      address_lat: issue.latitude,
      address_lon: issue.longitude,
      category: issue.category&.triage_external_id || issue.category&.name,
      subcategory: issue.subcategory&.name,
      subtype: issue.subtype&.name,
      state: state,
      ops_state: ops_state,
      portal_url: Rails.application.routes.url_helpers.issue_url(issue),
      anonymous: issue.anonymous, # TODO add logic to handle legacy logic here (anonymous user)
      responsible_subject: issue.responsible_subject&.then { |s|
        { "label" => s.subject_name, "value" => s.id }
      } || {},
      owner_id: owner_id,
      created_at: issue.created_at,
      likes_count: issue.likes.count,
      portal_public: issue.public,
      origin: DEFAULT_ORIGIN,
      article: {
        origin_by_id: issue.author.external_id,
        body: issue.description.presence || "(bez popisu)",
        type: DEFAULT_ARTICLE_TYPE,
        attachments: issue.photos.map do |photo|
          {
            "filename" => photo.filename.to_s,
            "data" => Base64.encode64(photo.variable? ? photo.variant(:full).processed.download : photo.download),
            "mime-type" => photo.content_type
          }
        end,
        sender: sender,
        created_at: issue.created_at
      },
    )

    # TODO custom error
    raise unless ticket.id
    ticket.id
  end

  def create_ticket_from_issue_update!(issue_update)
    issue = issue_update.activity.issue
    issue_ticket = @client.ticket.find(issue.resolution_external_id)

    if issue_update.author && !issue_update.author.external_id
      issue_update.author.update!(external_id: create_customer!(issue_update.author))
    end

    ticket = @client.ticket.create(
      number: issue_update.ticket_number,
      ops_issue_identifier: issue_update.id,
      process_type: "portal_issue_verification",
      title: "#{issue_update.resolves_issue? ? "Overenie" : "Aktualizácia"} podnetu #{issue_update.issue.title || 'Bez názvu'}",
      description: issue_update.text.presence || "(bez popisu)",
      group: issue_ticket.group,
      customer_id: issue_update.author&.external_id,
      origin_by_id: issue_update.author&.external_id,
      ops_state: "waiting",
      portal_url: "#{Rails.application.routes.url_helpers.issue_url(issue)}\#komentar_#{issue_update.id}",
      issue_resolved: issue_update.resolves_issue? ? "yes" : "no",
      likes_count: issue_update.activity.likes_count,
      origin: DEFAULT_ORIGIN,
      article: {
        origin_by_id: issue_update.author&.external_id,
        sender: DEFAULT_SENDER,
        type: DEFAULT_ARTICLE_TYPE,
        body: issue_update.text.presence || "(bez popisu)",
        attachments: issue_update.attachments.map do |photo|
          {
            "filename" => photo.filename.to_s,
            "data" => Base64.encode64(photo.variable? ? photo.variant(:full).processed.download : photo.download),
            "mime-type" => photo.content_type
          }
        end,
        created_at: issue_update.created_at
      },
      created_at: issue_update.created_at
    )

    raise unless ticket.id

    link_tickets!(parent_ticket_id: issue.resolution_external_id, child_ticket_id: ticket.id)

    ticket.id
  end

  def update_ticket!(ticket_id, ticket_params)
    ticket = @client.ticket.find(ticket_id)

    # TODO add more fields - this way?
    for key, value in ticket_params
      case key
      when "ops_state"
        ticket.ops_state = value
      when "responsible_subject"
        next if value[:label] == ticket.responsible_subject[:label] && value[:value].to_s == ticket.responsible_subject[:value].to_s
        ticket.previous_responsible_subject = ticket.responsible_subject
        ticket.responsible_subject = value
      when "investment"
        ticket.investment = value
      end
    end

    ticket.save
  end

  def sync_previous_responsible_subject!(ticket_id, previous_responsible_subject)
    ticket = @client.ticket.find(ticket_id)
    unless previous_responsible_subject[:label] == ticket.responsible_subject[:label] && previous_responsible_subject[:value].to_s == ticket.responsible_subject[:value].to_s
      ticket.previous_responsible_subject = previous_responsible_subject
      ticket.save
    end
  end

  def close_ticket!(ticket_id)
    ticket = @client.ticket.find(ticket_id)
    ticket.state = "closed"
    ticket.save
  end

  def update_ticket_from_issue!(ticket_id, issue, update_attachments: false)
    ticket = @client.ticket.find(ticket_id)

    ticket.title = issue.title
    ticket.description = issue.description
    ticket.issue_type = issue.issue_type
    ticket.address_state = issue.address_region # TODO rename this?
    ticket.address_county = issue.address_district # TODO rename this?
    ticket.address_municipality = build_ticket_municipality(issue)
    ticket.address_postcode = issue.address_postcode
    ticket.address_street = issue.address_street
    ticket.address_house_number = issue.address_house_number
    ticket.address_lat = issue.latitude
    ticket.address_lon = issue.longitude
    ticket.ops_state = issue.state.key
    ticket.category = issue.category&.triage_external_id || issue.category&.name
    ticket.subcategory = issue.subcategory&.name
    ticket.subtype = issue.subtype&.name
    ticket.likes_count = issue.likes_count
    ticket.responsible_subject = issue.responsible_subject&.then { |s| { label: s.name, value: s.id } }

    ticket.save

    update_ticket_attachments!(ticket_id, issue) if update_attachments
  end

  def update_ticket_attachments!(ticket_id, issue)
    ticket = @client.ticket.find(ticket_id)

    attachment_update_articles = ticket.articles.select { | article| article.type == ATTACHMENTS_UPDATE_ARTICLE_TYPE && article.body == ATTACHMENTS_UPDATE_ARTICLE_BODY }
    first_article = ticket.articles.first
    triage_attachments = [ first_article, attachment_update_articles ].flatten.map do |article|
      article.attachments.map do |attachment|
      {
        article_id: article.id,
        id: attachment.id,
        filename: attachment.filename,
        content_type: attachment.preferences.dig(:"Mime-Type") || attachment.preferences.dig(:"Content-Type"),
        size: attachment.size
      }
      end
    end.flatten

    local_attachments = issue.photos.map do |photo|
      {
        filename: photo.filename.to_s,
        content_type: photo.content_type,
        size: photo.variable? ? photo.variant(:full).processed.send(:record).image.blob.byte_size : photo.byte_size,
        attachment_object: photo
      }
    end

    new_attachments = local_attachments.reject do |photo|
      triage_attachments.any? { |attachment| attachment.values_at(:filename, :size, :content_type).map(&:to_s) == photo.values_at(:filename, :size, :content_type).map(&:to_s) }
    end

    attachments_to_delete = triage_attachments.reject do |attachment|
      local_attachments.any? { |photo| attachment.values_at(:filename, :size, :content_type).map(&:to_s) == photo.values_at(:filename, :size, :content_type).map(&:to_s) }
    end

    attachments_to_delete.each do |attachment|
      raw_api_request(:delete, "attachments/#{attachment[:id]}")
    end

    return if new_attachments.empty?

    article = ticket.article(
      origin_by_id: issue.author.external_id,
      content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
      body: ATTACHMENTS_UPDATE_ARTICLE_BODY,
      type: ATTACHMENTS_UPDATE_ARTICLE_TYPE,
      internal: false,
      attachments: new_attachments.map do |attachment|
        {
          "filename" => attachment[:filename],
          "mime-type" => attachment[:content_type],
          "data" => Base64.encode64(
            attachment[:attachment_object].variable? ?
              attachment[:attachment_object].variant(:full).processed.download : attachment[:attachment_object].download
          )
        }
      end
    )

    raise unless article.id
  end

  def find_article(ticket_id, article_id)
    begin
      ticket = @client.ticket.find(ticket_id)
      article = ticket.articles.find { |a| a.id == article_id.to_i }
      [  ticket, article ]
    rescue RuntimeError => e
      raise e unless e.message.include?("Couldn't find Ticket with") || e.message.include?("Couldn't find Article with")
      Rails.logger.info("Couldn't find article with id: #{article_id} in ticket with id: #{ticket_id}")
    end
  end

  def get_article(ticket_id, article_id, allowed_article_types: DEFAULT_ALLOWED_ARTICLE_TYPES, customer_articles: true, responsible_subject: nil)
    ticket, article = find_article(ticket_id, article_id)
    return unless ticket && article

    result = build_article_response(ticket, article, allowed_article_types: allowed_article_types, responsible_subject: responsible_subject)
    return unless result.present?
    result
  end

  def create_article!(ticket_id, activity_object, sender:)
    ticket = @client.ticket.find(ticket_id)

    article = ticket.article(
      uuid: activity_object.uuid,
      origin_by_id: activity_object.author&.external_id,
      content_type: DEFAULT_ARTICLE_CONTENT_TYPE,
      body: activity_object.triage_activity_body.presence || "(bez popisu)",
      type: DEFAULT_ARTICLE_TYPE,
      attachments: activity_object.attachments.map do |attachment|
        {
          "filename" => attachment.filename,
          "mime-type" => attachment.content_type,
          "data" => Base64.encode64(attachment.variable? ? attachment.variant(:full).processed.download : attachment.download)
        }
      end,
      created_at: activity_object.created_at,
      sender: sender
    )

    raise "No article ID returned" unless article.id
    article.id
  end

  def create_rs_portal_article!(ticket_id, activity_object)
    ticket = @client.ticket.find(ticket_id)

    article = ticket.article(
      uuid: activity_object.uuid,
      origin_by_id: activity_object.author&.external_id,
      content_type: "text/plain",
      body: activity_object.triage_activity_body.presence || "(bez popisu)",
      type: "email",
      to: "portal.responsible.subjects@odkazprestarostu.sk",
      attachments: activity_object.attachments.map do |attachment|
        {
          "filename" => attachment.filename,
          "mime-type" => attachment.content_type,
          "data" => Base64.encode64(attachment.variable? ? attachment.variant(:full).processed.download : attachment.download)
        }
      end,
      created_at: activity_object.created_at,
      sender: "Customer"
    )

    raise "No article ID returned" unless article.id
    article.id
  end

  def create_article_from_api!(author_id, ticket_id, activity)
    ticket = @client.ticket.find(ticket_id)

    article = ticket.article(
      origin_by_id: author_id,
      content_type: activity["content_type"],
      body: activity["body"],
      type: "note",
      internal: false,
      attachments: activity["attachments"].map do |attachment|
        {
          "filename" => attachment["filename"],
          "mime-type" => attachment["content_type"],
          "data" => attachment["data64"]
        }
      end,
      created_at: activity["created_at"],
    )

    raise "No article ID returned" unless article.id
    article.id
  end

  def create_system_note!(ticket_id, body, content_type: "text/plain", type: "note", internal: true, sender: "System")
    ticket = @client.ticket.find(ticket_id)

    last_matching = ticket.articles.select { |a| a.internal == internal && a.sender == sender && a.body == body }.last
    return last_matching.id if last_matching && last_matching.id == ticket.articles.last.id

    article = ticket.article(
      content_type: content_type,
      body: body,
      type: type,
      internal: internal,
      sender: sender
    )

    # TODO custom error
    raise unless article.id
    article.id
  end

  def get_users
    @client.user.all
  end

  def find_user(user_id)
    begin
      @client.user.find(user_id)
    rescue RuntimeError => e
      raise e unless e.message.include?("Couldn't find User with")
      Rails.logger.info("Couldn't find user with id: #{user_id}")
    end
  end

  def add_user_to_group(user_identifier, group_name)
    user = @client.user.find(user_identifier)
    user_groups = user.groups
    user_groups[group_name] = "full"
    user.groups = user_groups

    user.save
  end

  def create_customer!(user)
    begin
      # TODO what if there is existing non-portal user?
      zammad_user = @client.user.create(
        firstname: user.display_name,
        login: "ops-user-#{user.id}",
        roles: [ "Portal User" ],
        origin: "portal"
      )
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user("ops-user-#{user.id}")
      raise "Can't find nor create triage zammad user with login: ops-user-#{user.id}" unless result
      result.id
    end
  end

  def update_customer(user)
    result = find_zammad_user("ops-user-#{user.id}")
    return false unless result

    result.firstname = user.display_name
    result.lastname = "" if user.anonymous?
    result.save
  end

  def create_agent!(user)
    begin
      zammad_user = @client.user.create(
        firstname: user.firstname,
        lastname: user.lastname,
        login: user.email,
        email: user.email,
        roles: [ "Agent" ]
      )
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user(user.email)
      raise "Can't find nor create triage zammad user with email: #{user.email}" unless result
      result.id
    end
  end

  def create_responsible_subject!(responsible_subject)
    begin
      zammad_user = @client.user.create(
        firstname: responsible_subject.subject_name,
        login: "ops-rs-#{responsible_subject.id}",
        roles: [ "Zodpovedný Subjekt" ],
      )
      zammad_user.id
    rescue RuntimeError => e
      raise e unless e.message.include? "is already used for another user."

      result = find_zammad_user(responsible_subject.subject_name)
      raise "Can't create triage zammad user for responsible subject: #{responsible_subject.subject_name}" unless result
      result.id
    end
  end

  def get_groups
    @client.group.all.page(1, 500) { }
  end

  def find_ticket_responsible_subject(ticket_id)
    @client.ticket.find(ticket_id).responsible_subject
  end

  def check_import_mode!(force: false)
    return if !force && @last_import_mode_check && @last_import_mode_check > 1.minute.ago

    response_body = raw_api_request(:get, "settings")
    import_mode_on = response_body.select { |attribute| attribute["name"] == "import_mode" }.first["state_current"]["value"]

    raise "Import mode OFF" unless import_mode_on

    @last_import_mode_check = Time.now
  end

  def link_tickets!(parent_ticket_id:, child_ticket_id:)
    child_ticket_number = @client.ticket.find(child_ticket_id).number
    raw_api_request(:post, "links/add", {
      link_type: "child",
      link_object_target: "Ticket",
      link_object_target_value: parent_ticket_id,
      link_object_source: "Ticket",
      link_object_source_number: child_ticket_number
    })
  rescue RuntimeError => e
    # 422 means the link already exists (enforced by Zammad's LinkUniquenessValidator and a DB unique index).
    # raw_api_request raises "Request failed with status 422" in this case, so the check is safe.
    raise e unless e.message.include?("422")
  end

  def get_ticket_resolution_parent_links(ticket_id)
    links = raw_api_request(:get, "links", { link_object: "Ticket", link_object_value: ticket_id })&.dig("links")
    return [] unless links

    ticket_ids = links.select { |link| link["link_object"] == "Ticket" && link["link_type"] == "parent" }.map { |link| link["link_object_value"] }
    ticket_ids.select { |id| @client.ticket.find(id).process_type == "portal_issue_resolution" }
  end

  def raw_api_request(method, endpoint, params = {})
    url = File.join(@url, "api/v1/", endpoint)
    connection = Faraday.new(url: url) do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter :net_http
    end

    response = connection.send(method) do |req|
      req.headers["Authorization"] = "Token token=#{@http_token}"
      req.body = params.to_json unless params.empty?
    end
  rescue StandardError => error
    raise error.response if error.respond_to?(:response) && error.response
    raise error
  else
    raise "Request failed with status #{response.status}" unless response.status < 400

    response.body
  end

  private

  def find_zammad_user(query)
    # searches user by email, firstname, lastname and login
    @client.user.search(query: query).first
  end

  def build_author_response(article_type, author, zammad_api_client: TriageZammadEnvironment.client.client)
    return DEFAULT_OPS_ADMIN_USER if [ :agent_portal_comment, :agent_portal_and_backoffice_comment, :agent_backoffice_comment ].include?(article_type)

    return unless author

    if [ :user_portal_comment ].include?(article_type)
      user_id = author.is_a?(User) ? author.external_id : author
      user = User.find_by(external_id: user_id)
      if user.nil?
        Rails.logger.warn("User with id: #{user_id} not found in Triage Zammad")
        nil
      else
        {
          firstname: user.firstname,
          lastname: user.lastname,
          uuid: user.uuid
        }
      end
    elsif article_type == :responsible_subject_portal_and_backoffice_comment
      responsible_subject = zammad_api_client.user.find(author.external_id)
      if responsible_subject.nil?
        Rails.logger.warn("Responsible subject with id: #{author.external_id} not found in Triage Zammad")
        nil
      else
        {
          firstname: responsible_subject.firstname,
          lastname: responsible_subject.lastname,
          uuid: responsible_subject.uuid,
          responsible_subject_identifier: responsible_subject.id
        }
      end
    end
  end

  def build_ticket_municipality(issue)
    if issue.municipality_district.present?
      "#{issue.municipality&.name}::#{issue.municipality_district.name}"
    else
      issue.municipality&.name
    end
  end

  def build_issue_ticket_response(ticket)
    raise "Ticket from triage #{ticket.id} is missing address municipality" unless ticket.address_municipality.present?

    municipality_name, district_name = ticket.address_municipality.split("::", 2)
    municipality = Municipality.find_by!(name: municipality_name)
    municipality_district = municipality&.municipality_districts&.find_by(name: district_name)

    category = Issues::Category.find_by(name: ticket.category) || Issues::Category.find_by(triage_external_id: ticket.category)
    subcategory = category&.subcategories&.find_by(name: ticket.subcategory)
    subtype = subcategory&.subtypes&.find_by(name: ticket.subtype)

    ops_state = Issues::State.find_by!(key: ticket.ops_state)

    responsible_subject = ResponsibleSubject.find_by(id: ticket.responsible_subject&.[](:value))
    previous_responsible_subject = ResponsibleSubject.find_by(id: ticket.previous_responsible_subject[:value]) if ticket.previous_responsible_subject.present?

    {
      triage_identifier: ticket.id,
      ops_issue_identifier: ticket.ops_issue_identifier,
      triage_group: ticket.group,
      triage_owner_id: ticket.owner_id,
      ops_state: ops_state,
      origin: ticket.origin,
      process_type: ticket.process_type,
      title: ticket.title,
      description: ticket.description,
      author: ticket.anonymous ? nil : User.find_by(external_id: ticket.customer_id || ticket.created_by_id),
      author_response: build_author_response(:user_portal_comment, ticket.customer_id || ticket.created_by_id),
      responsible_subject: responsible_subject,
      previous_responsible_subject: previous_responsible_subject,
      issue_type: ticket.issue_type,
      category: category,
      subcategory: subcategory,
      subtype: subtype,
      address_state: ticket.address_state,
      address_county: ticket.address_county,
      municipality: municipality,
      municipality_district: municipality_district,
      address_postcode: ticket.address_postcode,
      address_street: ticket.address_street,
      address_lat: ticket.address_lat,
      address_lon: ticket.address_lon,
      address_house_number: ticket.address_house_number,
      likes_count: ticket.likes_count,
      portal_url: ticket.portal_url,
      created_at: ticket.created_at,
      updated_at: ticket.updated_at
    }
  end

  def build_article_response(ticket, article, allowed_article_types:, responsible_subject: nil, first_article: false)
    article_type = get_article_type(article, ticket.process_type)
    return unless first_article || allowed_article_types.include?(article_type)

    if article_type == :agent_backoffice_comment
      return unless responsible_subject
      return unless ticket.responsible_subject&.dig(:value)&.to_i == responsible_subject.id

      responsible_subject_changed_at = ticket.responsible_subject_changed_at
      return if responsible_subject_changed_at.present? && article.created_at < responsible_subject_changed_at
    end

    author = case article_type
    when :user_portal_comment, :user_private_comment
      if ticket.anonymous? && article.origin_by_id == ticket.customer_id
        nil
      else
        User.find_by(external_id: article.origin_by_id || article.created_by_id)
      end
    when :responsible_subject_portal_and_backoffice_comment
      result = ResponsibleSubject.find_by(external_id: article.origin_by_id || article.created_by_id)

      unless result.present?
        article_author = @client.user.find(article.origin_by_id || article.created_by_id)
        organization = article_author&.organization
        raise "Responsible subject article author has no organization" unless organization.present?

        result = ResponsibleSubject.find_by(subject_name: organization)
      end

      result
    end

    body = strip_tags_from_article_body(article.body)
    content_type = article.content_type
    if article.type == "email"
      body = strip_tags_from_article_body(EmailParser.parse_text(body)) if body.presence
      content_type = "text/plain"
    end

    {
      article_type: article_type,
      uuid: article.uuid,
      author: author,
      author_response: build_author_response(article_type, author),
      triage_identifier: article.id,
      content_type: content_type,
      body: body,
      created_at: article.created_at,
      updated_at: article.updated_at,
      attachments: article.attachments.map do |attachment|
        content_type = attachment.preferences.dig(:"Mime-Type") || attachment.preferences.dig(:"Content-Type")
        {
          triage_identifier: attachment.id,
          filename: attachment.filename,
          content_type: content_type,
          data64: Base64.strict_encode64(attachment.download)
        } unless content_type == "text/html"
      end.compact
    }
  end

  def strip_tags_from_article_body(body)
    tags = MARKED_AS_RESOLVED_TAGS + REFERRED_TAGS + [ RESPONSIBLE_SUBJECT_ARTICLE_TAG, OPS_PORTAL_ARTICLE_TAG ]
    body.gsub(Regexp.union(tags), "").strip
  end

  def get_article_type(article, process_type, zammad_api_client: @client)
    return if article.internal
    return :system_note if article.sender == "System"

    case process_type
    when "portal_issue_triage"
      return :user_private_comment if article.sender == "Customer" && article.type == "web"
      return :agent_private_comment if article.sender == "Agent"
      return :user_attachment_update if article.sender == "Customer" && article.type == ATTACHMENTS_UPDATE_ARTICLE_TYPE

    when "portal_issue_resolution"
      return :unknown_user_portal_comment if article.sender == "Customer" && article.origin_by_id == nil && article.created_by_id == ENV.fetch("TRIAGE_ZAMMAD_TECH_USER_ID").to_i

      article_author = zammad_api_client.user.find(article.origin_by_id || article.created_by_id)
      return :user_portal_comment if article.sender == "Customer" && article_author&.origin == "portal"

      if article.sender == "Customer" && responsible_subject_article_author?(article_author)
        return if automated_email?(article)

        return :responsible_subject_portal_and_backoffice_comment
      end

      if article.body.include?(OPS_PORTAL_ARTICLE_TAG)
        if article.body.include?(RESPONSIBLE_SUBJECT_ARTICLE_TAG)
          return :agent_portal_and_backoffice_comment if article.sender == "Agent"
        else
          return :agent_portal_comment if article.sender == "Agent"
        end
      elsif article.body.include?(RESPONSIBLE_SUBJECT_ARTICLE_TAG)
        return :agent_backoffice_comment if article.sender == "Agent"
      else
        return nil
      end
    else
      # TODO add more process_types
      raise "Unknown process type: #{process_type}"
    end

    raise "Unknown article type: #{article.type} for process type: #{process_type}"
  end

  def responsible_subject_article_author?(article_author)
    article_author&.organization.present? || article_author&.roles&.include?("Zodpovedný Subjekt")
  end

  def automated_email?(article)
    return false unless article.type == "email"

    preferences = article.respond_to?(:preferences) ? article.preferences : {}
    auto_submitted = preferences&.[]("Auto-Submitted") || preferences&.[](:"Auto-Submitted")
    return true if [ "auto-generated", "auto-replied" ].include?(auto_submitted.to_s.downcase)

    sender = article.respond_to?(:from) ? article.from.to_s : ""
    subject = article.respond_to?(:subject) ? article.subject.to_s : ""

    AUTOMATED_EMAIL_SENDER_PATTERNS.any? { |pattern| sender.match?(pattern) } ||
      AUTOMATED_EMAIL_SUBJECT_PATTERNS.any? { |pattern| subject.match?(pattern) }
  end
end
