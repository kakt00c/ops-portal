class Triage::SendNewIssueFromTriageToBackofficeJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject_data = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    responsible_subject = ResponsibleSubject.find(responsible_subject_data[:value])

    raise "Responsible subject not found: #{responsible_subject_data[:value]}" unless responsible_subject
    return unless responsible_subject.pro?

    raise "No clients found for responsible subject: #{responsible_subject.subject_name}" if responsible_subject.clients.empty?

    responsible_subject.clients.each do |client|
      webhook_client.new(client).issue_created(ticket_id)
    end
  end
end
