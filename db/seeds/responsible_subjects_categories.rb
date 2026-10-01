def link_rs_to_categories(subject_name, *category_names)
  rs = ResponsibleSubject.find_by!(subject_name: subject_name)
  category_names.each do |category_name|
    category = Issues::Category.find_by!(name: category_name)
    ResponsibleSubjects::Category.find_or_create_by!(
      responsible_subject: rs,
      issues_category: category
    )
  end
end

all_legacy_categories = [
  "Cesty a chodníky",
  "Zeleň a životné prostredie",
  "Dopravné značenie",
  "Mestský mobiliár",
  "Automobily",
  "Verejné služby",
  "Verejný poriadok"
]

link_rs_to_categories("Hlavné mesto SR Bratislava", *all_legacy_categories)

[
  "MÚ Nové Mesto",
  "MÚ Rača",
  "MÚ Vajnory",
  "MÚ Karlova Ves",
  "MÚ Dúbravka",
  "MÚ Lamač",
  "MÚ Devín",
  "MÚ Devínska Nová Ves"
].each do |name|
  link_rs_to_categories(name, *all_legacy_categories)
end

[
  "Mesto Banská Bystrica",
  "Trnava",
  "Nitra",
  "Malacky",
  "Pezinok"
].each do |name|
  link_rs_to_categories(name, *all_legacy_categories)
end

link_rs_to_categories("Dopravný podnik Bratislava, a.s.", "Cesty a chodníky", "Dopravné značenie")
link_rs_to_categories("Mestské lesy v Bratislave", "Zeleň a životné prostredie")
link_rs_to_categories("OLO Bratislava", "Verejné služby")
link_rs_to_categories("Mestská polícia hlavného mesta SR Bratislavy", "Verejný poriadok")
link_rs_to_categories("Národná diaľničná spoločnosť", "Cesty a chodníky")
