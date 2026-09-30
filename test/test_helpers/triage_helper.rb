module TriageHelper
  # Mirrors the hash ZammadApiClient#get_ticket returns for a portal issue ticket.
  def triage_ticket(issue, process_type: "portal_issue_resolution", ops_state: issue.state, **overrides)
    {
      triage_identifier: process_type == "portal_issue_triage" ? issue.triage_external_id : issue.resolution_external_id,
      ops_issue_identifier: issue.id,
      triage_group: "Dobrovoľníci::Trenčín",
      triage_owner_id: nil,
      ops_state: ops_state,
      origin: "portal",
      process_type: process_type,
      title: issue.title,
      description: issue.description,
      author: issue.author,
      responsible_subject: issue.responsible_subject,
      previous_responsible_subject: nil,
      issue_type: issue.issue_type,
      category: issue.category,
      subcategory: issue.subcategory,
      subtype: issue.subtype,
      address_state: "Bratislavský kraj",
      address_county: "Bratislava I",
      municipality: issue.municipality,
      municipality_district: issue.municipality_district,
      address_postcode: "81101",
      address_street: "Hlavná",
      address_lat: 48.1486,
      address_lon: 17.1077,
      address_house_number: "1",
      likes_count: 0,
      portal_url: "http://localhost:3000/dopyty/#{issue.id}",
      created_at: issue.created_at,
      updated_at: issue.updated_at
    }.merge(overrides)
  end

  def triage_article(article_type:, body: "Text článku", author: nil, attachments: [])
    {
      article_type: article_type,
      uuid: SecureRandom.uuid,
      author: author,
      author_response: nil,
      triage_identifier: 1,
      content_type: "text/plain",
      body: body,
      created_at: Time.current,
      updated_at: Time.current,
      attachments: attachments
    }
  end

  def triage_attachment(filename: "photo.jpg", content_type: "image/jpeg")
    {
      triage_identifier: 1,
      filename: filename,
      content_type: content_type,
      data64: Base64.strict_encode64(file_fixture("avatar.png").binread)
    }
  end

  def last_enqueued_arguments(job_class)
    job = enqueued_jobs.reverse.find { |j| j["job_class"] == job_class.name }
    ActiveJob::Arguments.deserialize(job["arguments"])
  end
end
