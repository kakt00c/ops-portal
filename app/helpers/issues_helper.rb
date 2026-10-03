module IssuesHelper
  def format_draft_address(draft)
    return "Nezistené" unless draft.address_data
    street = [ draft.address_street, draft.address_house_number ].compact.join(" ")
    [ street, draft.address_municipality, draft.address_city ].compact.join(", ")
  end

  def format_issue_address(issue)
    [ issue.address_street.presence, issue.municipality_district&.name, issue.municipality&.name ].compact.join(", ")
  end

  # The single active municipality the issue list is filtered to, if any.
  # Used to give each municipality's list its own title and canonical URL.
  def listed_municipality
    name = Array(params[:obec]).compact_blank
    return unless name.one?

    @listed_municipality ||= Municipality.active.find_by(name: name.first)
  end

  def search_issues_path(params = {})
    if @search_results
      issues_path(@search_results.search_params.merge(params))
    else
      issues_path(params)
    end
  end

  def praise_image_tag(issue)
    image_tag "pochvala-#{(issue.id % 6) + 1}.png", alt: "Pochvala"
  end

  def issue_effective_date(issue, **options)
    date = issue.resolution_started_at || issue.created_at
    l(date.to_date, **options)
  end

  def issue_state_badge(issue, html_options = {})
    name = issue.archived? ? "Archivovaný" : issue.state.name

    html_options[:class] = class_names(
      "state",
      "state-#{name.parameterize}",
      html_options[:class]
    )

    tag.div(name, **html_options)
  end
end
