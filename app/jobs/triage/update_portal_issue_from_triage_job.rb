class Triage::UpdatePortalIssueFromTriageJob < ApplicationJob
  def perform(ticket)
    issue = TriageUtils.get_issue_from_ticket(ticket)

    ops_state = ticket[:ops_state]
    if ticket[:issue_type] == "praise" && ops_state.key == "unresolved"
      ops_state = Issues::State.find_by!(key: "resolved_private")
    end

    if issue.responsible_subject && (issue.responsible_subject != ticket[:responsible_subject])
      Triage::SyncPreviousResponsibleSubjectJob.perform_later(issue, issue.responsible_subject)
    end

    issue.update!(
      title: ticket[:title],
      description: ticket[:description],
      municipality: ticket[:municipality],
      municipality_district: ticket[:municipality_district],
      address_region: ticket[:address_state],
      address_district: ticket[:address_county],
      address_postcode: ticket[:address_postcode],
      address_street: ticket[:address_street],
      address_house_number: ticket[:address_house_number],
      latitude: ticket[:address_lat],
      longitude: ticket[:address_lon],
      category: ticket[:category],
      subcategory: ticket[:subcategory],
      subtype: ticket[:subtype],
      state: ops_state,
      responsible_subject: ticket[:responsible_subject],
      issue_type: ticket[:issue_type],
    )

    if issue.should_create_rejection_note_in_triage?
      Triage::CreateRejectionSystemNoteJob.perform_later(issue)
    end

    return unless issue.should_create_resolution_process?

    Triage::CreateIssueResolutionProcessTicketJob.perform_later(issue, triage_group: ticket[:triage_group], triage_owner_id: ticket[:triage_owner_id])
  end
end
