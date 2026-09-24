class Triage::SendNewIssueUpdateFromTriageToBackofficeJob < ApplicationJob
  def perform(ticket_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject_data = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    responsible_subject = ResponsibleSubject.find(responsible_subject_data[:value])

    return unless responsible_subject.pro?

    raise "No clients found for responsible subject: #{responsible_subject.label}" if responsible_subject.clients.empty?

    responsible_subject.clients.each do |client|
      webhook_client.new(client).issue_updated(ticket_id)
    end
  end
end
