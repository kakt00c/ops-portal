class SyncIssueActivityObjectToTriageJob < ApplicationJob
  def perform(issue:, activity_object:, triage_group: nil, client: TriageZammadEnvironment.client, import: false)
    if activity_object.is_a?(Issues::Update)
      create_portal_issue_verification_process(activity_object, client) unless activity_object.external_id.present?
      return unless activity_object.confirmed? && activity_object.published?
    end

    return if activity_object.triage_external_id.present?

    client.check_import_mode! if import

    find_or_create_triage_portal_user!(activity_object.author, client, user_group: triage_group) if activity_object.author && !activity_object.author.external_id

    external_id = issue.triage_process? ? issue.triage_external_id : issue.resolution_external_id

    begin
      article_id = if activity_object.author.is_a?(User::Citizen) || activity_object.author.is_a?(Legacy::Agent) ||  activity_object.author.is_a?(NilClass)
        client.create_article!(external_id, activity_object, sender: sender_type(activity_object))
      elsif activity_object.author.is_a?(ResponsibleSubject) || activity_object.author.is_a?(::ResponsibleSubjects::User)
        client.create_rs_portal_article!(external_id, activity_object)
      else
        raise "Unsupported author type: #{activity_object.author.class.name}"
      end

      raise "No article ID returned" unless article_id

      activity_object.update!(
        triage_external_id: article_id
      )
    rescue RuntimeError => e
      raise e unless /.*This object already exists/.match?(e.message)

      search_result = client.client.ticket.find(external_id).articles.select { |a| a.uuid == activity_object.uuid }

      raise e unless search_result.count == 1

      activity_object.update!(
        triage_external_id: search_result.first.id
      )
    end
  end

  def create_portal_issue_verification_process(issue_update, client)
    external_id = client.create_ticket_from_issue_update!(issue_update)
    issue_update.update!(external_id: external_id)

  rescue RuntimeError => e
    raise e unless /.*This object already exists/.match?(e.message) || /.*Can't save object \(ZammadAPI::Resources::Ticket\): Error ID.*/.match?(e.message)

    search_result = client.client.ticket.search(query: "\"#{issue_update.ticket_number}\"").select { |r| r.number == issue_update.ticket_number }

    raise e if search_result.count == 0
    raise "Found multiple matches for ticket!" unless search_result.count == 1

    ticket = search_result.first
    issue_update.update!(external_id: ticket.id)

    client.link_tickets!(parent_ticket_id: issue_update.issue.resolution_external_id, child_ticket_id: ticket.id) if issue_update.issue.resolution_external_id
  end

  def find_or_create_triage_portal_user!(user, client, user_group: nil)
    return user if user.external_id

    if user.is_a?(User::Citizen)
      user.update!(external_id: client.create_customer!(user))
    elsif user.is_a?(User::ResponsibleSubject)
      external_id = client.create_responsible_subject!(user.responsible_subject)

      user.update!(external_id: external_id)
      user.responsible_subject.update!(external_id: external_id)
    elsif user.is_a?(Legacy::Agent)
      user.update!(external_id: client.create_agent!(user))
      client.add_user_to_group(user.external_id, user_group)
    elsif user.is_a?(::ResponsibleSubjects::User) && user.responsible_subject
      user.responsible_subject.update!(external_id: client.create_responsible_subject!(user.responsible_subject))
    elsif user.is_a?(::ResponsibleSubject)
      user.update!(external_id: client.create_responsible_subject!(user))
    end

    user
  end

  def sender_type(activity_object)
    case activity_object
    when Issues::AgentComment, Issues::AgentPrivateComment
      "Agent"
    when Legacy::Issues::AgentInternalCommunication
      "Agent"
    when Issues::UserComment, Issues::UserPrivateComment, Issues::DuplicateIssueComment
      "Customer"
    when Issues::ResponsibleSubjectComment
      "Customer"
    when Issues::Update
      "Customer"
    when Legacy::Issues::ResponsibleSubjectInternalCommunication
      "Customer"
    else
      raise "Unknown activity object type: #{activity_object.class.name}"
    end
  end
end
