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

# Seed triage categories with subcategories and subtypes (subset for development)

def seed_category(name)
  category = Issues::Category.find_or_initialize_by(name: name)
  category.save!
  yield(category) if block_given?
end

def seed_subcategory(category, name)
  subcategory = Issues::Subcategory.find_or_initialize_by(name: name, category: category)
  subcategory.save!
  yield(subcategory) if block_given?
end

def seed_subtype(subcategory, name)
  Issues::Subtype.find_or_initialize_by(name: name, subcategory: subcategory).save!
end

seed_category("Komunikácie") do |category|
  seed_subcategory(category, "cesta") do |subcategory|
    seed_subtype(subcategory, "výtlk")
    seed_subtype(subcategory, "rozbitá cesta (väčší úsek)")
    seed_subtype(subcategory, "znečistená")
    seed_subtype(subcategory, "neodhrnutá")
    seed_subtype(subcategory, "neposypaná")
    seed_subtype(subcategory, "rozkopaná")
    seed_subtype(subcategory, "poškodená dlažba")
  end
  seed_subcategory(category, "chodník") do |subcategory|
    seed_subtype(subcategory, "výtlk")
    seed_subtype(subcategory, "znečistený")
    seed_subtype(subcategory, "neodhrnutý")
    seed_subtype(subcategory, "neposypaný")
    seed_subtype(subcategory, "rozkopaný")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "poškodená dlažba")
    seed_subtype(subcategory, "bariéra na chodníku")
  end
  seed_subcategory(category, "cyklotrasa") do |subcategory|
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "neoznačená")
    seed_subtype(subcategory, "znečistená")
    seed_subtype(subcategory, "neodhrnutá")
    seed_subtype(subcategory, "neposypaná")
    seed_subtype(subcategory, "výtlk")
  end
  seed_subcategory(category, "schody") do |subcategory|
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "znečistená")
    seed_subtype(subcategory, "neodhrnutá")
    seed_subtype(subcategory, "neposypaná")
    seed_subtype(subcategory, "bariérové")
  end
  seed_subcategory(category, "podjazd/podchod") do |subcategory|
    seed_subtype(subcategory, "potrebná údržba")
  end
  seed_subcategory(category, "most/lávka") do |subcategory|
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "nevhodne umiestnená")
  end
end

seed_category("Osvetlenie") do |category|
  seed_subcategory(category, "osvetlenie") do |subcategory|
    seed_subtype(subcategory, "nefunknčné")
    seed_subtype(subcategory, "poškodený stĺp")
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "nedostatočné")
    seed_subtype(subcategory, "nevhodné (silné a pod.)")
  end
end

seed_category("Verejný poriadok") do |category|
  seed_subcategory(category, "reklama") do |subcategory|
    seed_subtype(subcategory, "nelegálna reklama")
    seed_subtype(subcategory, "nevhodne umiestnená")
    seed_subtype(subcategory, "nebezpečná (na spadnutie a pod)")
  end
  seed_subcategory(category, "neporiadok vo verejnom priestranstve") do |subcategory|
    seed_subtype(subcategory, "neodpratané lístie")
    seed_subtype(subcategory, "neporiadok vo verejnom priestore")
  end
  seed_subcategory(category, "vandalizmus") do |subcategory|
    seed_subtype(subcategory, "rušenie nočného pokoja")
    seed_subtype(subcategory, "pitie alkoholu na verejnom priestore")
  end
  seed_subcategory(category, "iné")
end

seed_category("Zeleň a znečisťovanie") do |category|
  seed_subcategory(category, "kosenie") do |subcategory|
    seed_subtype(subcategory, "nepravidelne")
  end
  seed_subcategory(category, "strom") do |subcategory|
    seed_subtype(subcategory, "suchý")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "neorezaný")
    seed_subtype(subcategory, "zlomený konár")
    seed_subtype(subcategory, "napadnutý")
    seed_subtype(subcategory, "invazívna rastlina")
    seed_subtype(subcategory, "poškodená podpera")
  end
  seed_subcategory(category, "krík") do |subcategory|
    seed_subtype(subcategory, "suchý")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "neorezaný")
  end
  seed_subcategory(category, "výsadba") do |subcategory|
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "neudržiavaná")
  end
  seed_subcategory(category, "ostatná starostlivosť") do |subcategory|
    seed_subtype(subcategory, "iné")
  end
  seed_subcategory(category, "znečisťovanie") do |subcategory|
    seed_subtype(subcategory, "voda, pôda, ovzdušie")
  end
end

seed_category("Zvieratá") do |category|
  seed_subcategory(category, "zver v meste") do |subcategory|
    seed_subtype(subcategory, "premnožené hlodavce")
  end
  seed_subcategory(category, "výbehy pre zvieratá") do |subcategory|
    seed_subtype(subcategory, "lesná zver")
    seed_subtype(subcategory, "túlavé mačky/psy")
    seed_subtype(subcategory, "hmyz")
  end
  seed_subcategory(category, "domáce zvieratá") do |subcategory|
    seed_subtype(subcategory, "výbehy pre zvieratá")
    seed_subtype(subcategory, "majitelia - neplnenie povinností")
  end
  seed_subcategory(category, "mŕtvy živočích")
  seed_subcategory(category, "iné")
end

seed_category("Skládky a vraky") do |category|
  seed_subcategory(category, "nelegálne skládky")
  seed_subcategory(category, "vraky motorových vozidiel")
  seed_subcategory(category, "kontajnerové stanovištia") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
  end
  seed_subcategory(category, "kompostovanie") do |subcategory|
    seed_subtype(subcategory, "chýbajúce komunitné kompostovisko")
    seed_subtype(subcategory, "domácnosti")
  end
end

seed_category("Ostatné") do |category|
  seed_subcategory(category, "iné")
end
