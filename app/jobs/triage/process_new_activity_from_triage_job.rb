class Triage::ProcessNewActivityFromTriageJob < ApplicationJob
  def perform(ticket_id, article_id, triage_zammad_client: TriageZammadEnvironment.client, webhook_client: WebhookClient)
    responsible_subject_data = triage_zammad_client.find_ticket_responsible_subject(ticket_id)
    responsible_subject = ResponsibleSubject.find(responsible_subject_data[:value])

    return unless responsible_subject.pro?

    allowed_article_types = [
      :unknown_user_portal_comment,
      :user_portal_comment,
      :agent_portal_and_backoffice_comment,
      :agent_backoffice_comment,
      :agent_portal_comment
    ]

    article = triage_zammad_client.get_article(
      ticket_id,
      article_id,
      allowed_article_types: allowed_article_types,
      responsible_subject: responsible_subject
    )
    return unless article

    raise "No clients found for responsible subject: #{responsible_subject.label}" if responsible_subject.clients.empty?

    responsible_subject.clients.each do |client|
      webhook_client.new(client).activity_created(
        ticket_id,
        article_id,
        activity_type: article[:article_type]
      )
    end
  end
end
