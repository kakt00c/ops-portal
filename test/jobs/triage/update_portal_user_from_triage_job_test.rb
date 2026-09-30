require "test_helper"

class Triage::UpdatePortalUserFromTriageJobTest < ActiveJob::TestCase
  def perform(triage_user)
    client = Minitest::Mock.new
    client.expect :find_user, triage_user, [ 77 ]
    Triage::UpdatePortalUserFromTriageJob.new.perform(77, triage_zammad_client: client)
    assert_mock client
  end

  def triage_user(**attrs)
    OpenStruct.new({ id: 77, email: "agent@mesto.sk", firstname: "Anna", lastname: "Úradníčka", organization: nil, origin: "triage", banned: false }.merge(attrs))
  end

  test "triage user of a responsible subject organization gets a responsible subject account" do
    assert_difference -> { User::ResponsibleSubject.count }, 1 do
      perform triage_user(organization: responsible_subjects(:one).subject_name)
    end

    user = User::ResponsibleSubject.find_by!(external_id: 77)
    assert_equal "agent@mesto.sk", user.email
    assert_equal responsible_subjects(:one), user.responsible_subject
    assert user.verified?
    assert user.onboarded?
    assert user.phone_verified?
  end

  test "existing citizen with the same email is converted to a responsible subject" do
    citizen = users(:two)

    assert_no_difference -> { User.count } do
      perform triage_user(email: citizen.email, organization: responsible_subjects(:one).subject_name)
    end

    user = User.find(citizen.id)
    assert_kind_of User::ResponsibleSubject, user
    assert_equal responsible_subjects(:one), user.responsible_subject
    assert_equal "Anna", user.firstname
  end

  test "responsible subject user without organization becomes a citizen" do
    rs_user = users(:responsible_subject)

    perform triage_user(email: rs_user.email, organization: nil)

    user = User.find(rs_user.id)
    assert_kind_of User::Citizen, user
    assert_nil user.responsible_subject
  end

  test "ban from triage is applied to portal users" do
    citizen = users(:one) # external_id 1

    client = Minitest::Mock.new
    client.expect :find_user, triage_user(id: 1, email: citizen.email, origin: "portal", banned: true), [ 1 ]
    Triage::UpdatePortalUserFromTriageJob.new.perform(1, triage_zammad_client: client)

    assert citizen.reload.banned?
  end

  test "portal user unknown to the portal raises" do
    assert_raises(RuntimeError) do
      perform triage_user(email: "ghost@example.org", origin: "portal")
    end
  end

  test "missing triage user does nothing" do
    assert_no_difference -> { User.count } do
      perform nil
    end
  end
end
