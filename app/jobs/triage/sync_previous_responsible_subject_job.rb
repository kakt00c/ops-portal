module Triage
  class SyncPreviousResponsibleSubjectJob < ApplicationJob
    def perform(issue, previous_responsible_subject, client: TriageZammadEnvironment.client)
      return unless issue.resolution_process?

      client.sync_previous_responsible_subject!(issue.resolution_external_id, previous_responsible_subject)
    end
  end
end
