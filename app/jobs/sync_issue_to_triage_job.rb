class SyncIssueToTriageJob < ApplicationJob
  def perform(issue, client: TriageZammadEnvironment.client, import: false, sync_activities_to_triage_job: SyncIssueActivitiesToTriageJob, sync_activities: true)
    return if issue.archived?

    client.check_import_mode! if import

    triage_group = find_municipality_group(issue, client) if import

    if issue.resolution_process?
      client.update_ticket_from_issue!(issue.resolution_external_id, issue)
      issue.touch(:last_synced_at)

    elsif issue.triage_external_id.present?
      client.update_ticket_from_issue!(issue.triage_external_id, issue, update_attachments: true)
      issue.touch(:last_synced_at)

    else
      begin
        process_type = ISSUE_STATE_TO_PROCESS_TYPE.fetch(issue.state.name)
        ticket_id = create_new_triage_ticket(issue, triage_group: triage_group, process_type: process_type, client: client, import: import)
        raise unless ticket_id

        issue.last_synced_at = Time.now

        if process_type == "portal_issue_triage"
          issue.triage_external_id = ticket_id
        else
          issue.resolution_external_id = ticket_id
          issue.resolution_started_at ||= Time.now
        end

        issue.save!

      rescue RuntimeError => e
        raise e unless /.*This object already exists/.match?(e.message)

        issue_number = generate_issue_number(issue, process_type: process_type)

        search_result = client.client.ticket.search(query: "\"#{issue_number}\"").select { |r| r.number == issue_number }

        raise e if search_result.count == 0

        raise "Found multiple matches for ticket!" unless search_result.count == 1

        ticket = search_result.first

        issue.last_synced_at = Time.now

        if process_type == "portal_issue_triage"
          issue.triage_external_id = ticket.id
        else
          issue.resolution_external_id = ticket.id
          issue.resolution_started_at ||= ticket.created_at
        end

        issue.save!
      end
    end

    sync_activities_to_triage_job.perform_later(issue, triage_group: triage_group, import: import) if sync_activities
  end

  private

  def create_new_triage_ticket(issue, triage_group:, process_type:, client:, import:)
    find_or_create_triage_portal_user!(issue.author, client) unless issue.author&.external_id

    issue_number = generate_issue_number(issue, process_type: process_type)

    return client.create_ticket_from_issue!(issue, issue_number: issue_number) unless import

    if issue.owner
      find_or_create_triage_portal_user!(issue.owner, client, customer: false) unless issue.owner.external_id
      client.add_user_to_group(issue.owner.external_id, triage_group)
    end

    client.create_ticket_from_issue!(
      issue,
      issue_number: issue_number,
      process_type: process_type,
      state: ISSUE_OPS_STATE_TO_TRIAGE_STATE.fetch(issue.state.name),
      group: triage_group,
      owner_id: issue.owner&.external_id
    )
  end

  def find_or_create_triage_portal_user!(user, client, customer: true)
    return user if user.external_id

    user.external_id = if customer
     client.create_customer!(user)
    else
     client.create_agent!(user)
    end
    user.save!

    user
  end

  def generate_issue_number(issue, process_type:)
    case process_type
    when "portal_issue_triage"
      number_prefix = "T"
    when "portal_issue_resolution"
      number_prefix = "R"
    else
      raise "Unsupported process type: #{process_type}"
    end

    "#{number_prefix}-#{issue.id.to_s.rjust(4, '0')}"
  end

  def find_municipality_group(issue, client)
    if issue.municipality_district
      client.get_groups.select { |group| issue.municipality.name.in?(group.name) && issue.municipality_district.name&.in?(group.name) }[0].name
    else
      client.get_groups.select { |group| issue.municipality.name.in?(group.name) }[0].name
    end
  end

  ISSUE_STATE_TO_PROCESS_TYPE = {
    "Čakajúci" => "portal_issue_triage",
    "Zaslaný zodpovednému" => "portal_issue_resolution",
    "V riešení" => "portal_issue_resolution",
    "Odstúpený" => "portal_issue_resolution",
    "Označený za vyriešený" => "portal_issue_resolution",
    "Vyriešený" => "portal_issue_resolution",
    "Uzavretý" => "portal_issue_resolution",
    "Neriešený" => "portal_issue_resolution",
    "Neprijatý" => "portal_issue_resolution",
    "Zamietnutý" => "portal_issue_resolution",
    "Duplicitný" => "portal_issue_triage"
  }

  ISSUE_OPS_STATE_TO_TRIAGE_STATE = {
    "Čakajúci" => "new",
    "Zaslaný zodpovednému" => "open",
    "V riešení" => "open",
    "Odstúpený" => "open",
    "Označený za vyriešený" => "open",
    "Vyriešený" => "closed",
    "Uzavretý" => "closed",
    "Neriešený" => "closed",
    "Neprijatý" => "closed",
    "Zamietnutý" => "closed",
    "Duplicitný" => "closed"
  }
end
