require "test_helper"

class Triage::SyncTriageUsersJobTest < ActiveJob::TestCase
  test "creates portal users for triage users that do not exist yet" do
    client = Minitest::Mock.new
    client.expect :get_users, [
      OpenStruct.new(id: 1, email: "changed@example.org", firstname: "Changed", lastname: "Name"), # users(:one) has external_id 1
      OpenStruct.new(id: 555, email: "new.agent@example.org", firstname: "Nová", lastname: "Agentka")
    ]

    assert_difference -> { User.count }, 1 do
      Triage::SyncTriageUsersJob.new.perform(client: client)
    end

    assert_mock client
    assert_equal users(:one).email, users(:one).reload.email, "existing users are left untouched"
    created = User.find_by!(external_id: 555)
    assert_equal "new.agent@example.org", created.email
    assert_equal "Nová Agentka", created.display_name
  end
end
