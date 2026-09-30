[
  "Mestská časť",
  "Mesto",
  "Iný subjekt"
].each do |name|
  ResponsibleSubjects::Type.find_or_initialize_by(name: name).tap do |t|
    t.active = true
  end.save!
end

city_district = ResponsibleSubjects::Type.find_by!(name: "Mestská časť")
city = ResponsibleSubjects::Type.find_by!(name: "Mesto")
other = ResponsibleSubjects::Type.find_by!(name: "Iný subjekt")

[
  { type: city_district, subject_name: "MÚ Nové Mesto" },
  { type: city_district, subject_name: "MÚ Rača" },
  { type: city_district, subject_name: "MÚ Vajnory" },
  { type: city_district, subject_name: "MÚ Karlova Ves" },
  { type: city_district, subject_name: "MÚ Dúbravka" },
  { type: city_district, subject_name: "MÚ Lamač" },
  { type: city_district, subject_name: "MÚ Devín" },
  { type: city_district, subject_name: "MÚ Devínska Nová Ves" },
  { type: city_district, subject_name: "MÚ Staré Mesto" },
  { type: city_district, subject_name: "MÚ Ružinov" },
  { type: city_district, subject_name: "MÚ Vrakuňa" },
  { type: city_district, subject_name: "MÚ Podunajské Biskupice" },
  { type: city_district, subject_name: "MÚ Záhorská Bystrica" },
  { type: city_district, subject_name: "MÚ Petržalka" },
  { type: city_district, subject_name: "MÚ Jarovce" },
  { type: city_district, subject_name: "MÚ Rusovce" },
  { type: city_district, subject_name: "MÚ Čunovo" },

  { type: city, subject_name: "Hlavné mesto SR Bratislava" },
  { type: city, subject_name: "Mesto Banská Bystrica" },
  { type: city, subject_name: "Trnava" },
  { type: city, subject_name: "Nitra" },
  { type: city, subject_name: "Malacky" },
  { type: city, subject_name: "Pezinok" },

  { type: other, subject_name: "Národná diaľničná spoločnosť" },
  { type: other, subject_name: "Mestské lesy v Bratislave" },
  { type: other, subject_name: "Dopravný podnik Bratislava, a.s." },
  { type: other, subject_name: "Mestská polícia hlavného mesta SR Bratislavy" },
  { type: other, subject_name: "Iný subjekt" },
  { type: other, subject_name: "OLO Bratislava" }
].each do |data|
  bratislava = Municipality.find_by(name: "Bratislava")
  municipality, municipality_district = case data[:type]
  when city_district
    [ bratislava, bratislava&.municipality_districts&.find_by(name: data[:subject_name].delete_prefix("MÚ ")) ]
  when city
    [ Municipality.find_by(name: data[:subject_name].delete_prefix("Hlavné mesto SR ").delete_prefix("Mesto ")), nil ]
  else
    [ data[:subject_name].include?("Bratislav") ? bratislava : nil, nil ]
  end

  ResponsibleSubject.find_or_initialize_by(subject_name: data[:subject_name]).tap do |rs|
    rs.responsible_subjects_type = data[:type]
    rs.name = data[:subject_name]
    rs.municipality = municipality
    rs.municipality_district = municipality_district
    rs.email = "#{data[:subject_name].parameterize}@not-existing-domain.com"
    rs.active = true
    rs.pro = true
  end.save!
end
