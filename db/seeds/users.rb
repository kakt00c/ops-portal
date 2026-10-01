DEV_SEED_PASSWORD = "password"

def seed_user(email:, firstname:, lastname:, municipality_name: nil, type: User::Citizen, **attributes)
  user = User.find_or_initialize_by(email: email)
  user.assign_attributes(
    type: type.name,
    firstname: firstname,
    lastname: lastname,
    municipality: municipality_name && Municipality.find_by!(name: municipality_name),
    status: :verified,
    verified: true,
    onboarded: true,
    gdpr_accepted: true,
    phone_verified: true,
    **attributes
  )
  user.password_hash ||= RodauthApp.rodauth.allocate.password_hash(DEV_SEED_PASSWORD)
  user.save!
  user
end

seed_user(email: "admin@example.com", firstname: "Admin", lastname: "Adminovič", municipality_name: "Bratislava")
seed_user(email: "jana@example.com", firstname: "Jana", lastname: "Nováková", municipality_name: "Bratislava")
seed_user(email: "peter@example.com", firstname: "Peter", lastname: "Horváth", municipality_name: "Trnava")
seed_user(email: "anonym@example.com", firstname: "Anonym", lastname: nil, anonymous: true)
seed_user(email: "novy@example.com", firstname: "Nový", lastname: "Používateľ", phone_verified: false)

seed_user(
  email: "stare-mesto@example.com",
  firstname: "Úradník",
  lastname: "Starého Mesta",
  type: User::ResponsibleSubject,
  responsible_subject: ResponsibleSubject.find_by!(subject_name: "MÚ Staré Mesto")
)

Faker::Config.random = Random.new(42)
20.times do |n|
  seed_user(
    email: "citizen#{n + 1}@example.com",
    firstname: Faker::Name.first_name,
    lastname: Faker::Name.last_name,
    municipality_name: [ "Bratislava", "Bratislava", "Trnava", "Nitra", "Banská Bystrica", nil ][n % 6]
  )
end
Faker::Config.random = nil
