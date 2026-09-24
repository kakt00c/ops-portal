json.array! @issues do |issue|
  json.triage_identifier issue.resolution_external_id if issue.resolution_process?
  json.ops_issue_identifier issue.id
  json.ops_state issue.state&.key
end
