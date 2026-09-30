require "test_helper"

class Triage::CloseIssueUpdateTriageTicketJobTest < ActiveJob::TestCase
  def build_update(resolves_issue:)
    update = Issues::Update.new(text: "Text", author: users(:one), published: true, resolves_issue: resolves_issue, external_id: "700", legacy_id: 1)
    update.build_activity(issue: issues(:two), type: Issues::UpdateActivity)
    update.save!
    update
  end

  {
    [ true, "accepted" ] => "Overenie podnetu bolo prijaté.",
    [ true, "rejected" ] => "Overenie podnetu bolo zamietnuté.",
    [ false, "accepted" ] => "Aktualizácia podnetu bola prijatá.",
    [ false, "rejected" ] => "Aktualizácia podnetu bola zamietnutá."
  }.each do |(resolves_issue, state), note|
    test "closes the ticket and notes '#{note}'" do
      update = build_update(resolves_issue: resolves_issue)
      client = Minitest::Mock.new
      client.expect :close_ticket!, nil, [ "700" ]
      client.expect :create_system_note!, 1, [ "700", note ]

      Triage::CloseIssueUpdateTriageTicketJob.new.perform(update, state, triage_zammad_client: client)

      assert_mock client
    end
  end
end
