# Some legacy categories

[
  { triage_external_id: 1, name: "Cesty a chodníky", name_hu: "Közutak és közterület", alias: "cesty-a-dopravne-znacenie", description: "cesty, cyklotrasy, schody, oplotenie", description_hu: "utak, kerékpárutak, lépcsők, kerítések", weight: 1000, legacy_id: 16 },
  { triage_external_id: 2, name: "Zeleň a životné prostredie", name_hu: "Zöldterületek", alias: "priroda-a-zivotne-prostredie", description: "stromy, neporiadok, znečisťovanie", description_hu: "fák, rendetlenség, szennyezés", weight: 900, legacy_id: 1 },
  { triage_external_id: 3, name: "Dopravné značenie", name_hu: "Közúti jelzések", alias: "dopravne-znacenie", description: "značky, semafory, stĺpiky", description_hu: "jelzőtáblák, közlekedési lámpák, pollerek", weight: 800, legacy_id: 25 },
  { triage_external_id: 4, name: "Mestský mobiliár", name_hu: "Közterületek berendezései ", alias: "Mestský mobiliár", description: "koše, ihriská, lavičky, zastávky MHD", description_hu: "szemétkosarak, játszóterek, padok, tömegközlekedési megállók", weight: 700, legacy_id: 9 },
  { triage_external_id: 5, name: "Automobily", name_hu: "Gépjármûvek", alias: " Automobily", description: "parkovanie, dlhodobo odstavené vozidlá", description_hu: "parkolás, elhagyott járművek", weight: 600, legacy_id: 184 },
  { triage_external_id: 6, name: "Verejné služby", name_hu: "Közszolgáltatások", alias: "kanalizacia", description: "osvetlenie, kanalizácia, MHD, web, rozvodné siete", description_hu: "közvilágítás, csatornahálózat, városi tömegközlekedés, honlap, közműhálózat", weight: 500, legacy_id: 14 },
  { triage_external_id: 7, name: "Verejný poriadok", name_hu: "Közrend", alias: "verejny-poriadok", description: "stavby, reklama, vandalizmus", description_hu: "építkezések, reklámok, vandalizmus", weight: 400, legacy_id: 21 }
].each do |category|
  cat = Issues::Category.find_or_initialize_by(
    name: category[:name],
    name_hu: category[:name_hu],
    alias: category[:alias],
    description: category[:description],
    description_hu: category[:description_hu],
    weight: category[:weight],
    legacy_id: category[:legacy_id]
  ).tap do |c|
    c.triage_external_id = category[:triage_external_id]
  end

  cat.save!
end
