class Triage::UpdatePortalUserFromTriageJob < ApplicationJob
  def perform(user_id, triage_zammad_client: TriageZammadEnvironment.client)
    triage_user = triage_zammad_client.find_user(user_id)
    return unless triage_user

    rs = ResponsibleSubject.find_by(subject_name: triage_user.organization) if triage_user.organization.present?

    user = User.find_by(external_id: triage_user.id.to_i)
    user ||= User.find_by(email: triage_user.email)

    if rs
      if user
        user = user.becomes(User::ResponsibleSubject) if user.is_a?(User::Citizen)

        user.update!(
          type: "User::ResponsibleSubject",
          firstname: triage_user.firstname,
          lastname: triage_user.lastname,
          email: triage_user.email,
          responsible_subject: rs,
        )
      else
        User::ResponsibleSubject.create!(
          firstname: triage_user.firstname,
          lastname: triage_user.lastname,
          email: triage_user.email,
          external_id: triage_user.id.to_i,
          responsible_subject: rs,
          status: :verified,
          onboarded: true,
          password: SecureRandom.hex(32),
          phone_verified: true
        )
      end
    elsif user&.responsible_subject
      user = user.becomes(User::Citizen)

      user.update!(
        type: "User::Citizen",
        responsible_subject_id: nil
      )
    elsif triage_user.origin == "portal" && user.nil?
      raise "User with email #{triage_user.email} not found in the portal, but exists in triage."
    end

    return unless triage_user.origin == "portal"

    user = User.find_by!(external_id: triage_user.id.to_i)
    user.update!(banned: triage_user.banned) unless triage_user.banned == user.banned
  end
end
