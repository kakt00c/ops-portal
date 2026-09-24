class Triage::CreateRejectionSystemNoteJob < ApplicationJob
  def perform(issue, triage_zammad_client: TriageZammadEnvironment.client)
    triage_zammad_client.create_system_note!(
      issue.resolution_process? ? issue.resolution_external_id : issue.triage_external_id,
      "Podnet bol zamietnutý."
    )
  end
end
