# Development issues spread over municipalities, categories, states and time,
# with photos, comments, likes and subscriptions. Deterministic (fixed random
# seed), so the same searches return the same results after reseeding.
#
# Titles and descriptions use real words with diacritics, so fulltext search
# can be tested with and without accents (e.g. "vytlk" finds "výtlk").
#
# Runs only on an empty issues table; use `bin/rails db:seed:replant` to reseed.
# SEED_ISSUES_COUNT overrides the number of generated issues.

ISSUE_TEMPLATES = [
  { category: "Komunikácie", subcategory: "cesta", subtype: "výtlk", photo: "road",
    titles: [ "Hlboký výtlk na ceste %{street}", "Výtlk uprostred jazdného pruhu" ],
    descriptions: [ "Na ulici %{street} je už niekoľko týždňov hlboký výtlk, autá ho musia obchádzať a v noci je takmer neviditeľný.", "Po zime sa na vozovke objavil veľký výtlk, ktorý poškodzuje pneumatiky. Prosím o opravu čo najskôr." ] },
  { category: "Komunikácie", subcategory: "cesta", subtype: "rozbitá cesta (väčší úsek)", photo: "road",
    titles: [ "Rozbitý asfalt na dlhom úseku cesty", "Cesta %{street} je v dezolátnom stave" ],
    descriptions: [ "Celý úsek cesty na ulici %{street} je rozbitý, asfalt sa rozpadá a vznikajú hlboké jamy. Treba nový povrch." ] },
  { category: "Komunikácie", subcategory: "cesta", subtype: "neodhrnutá", photo: "road",
    titles: [ "Neodhrnutý sneh na ceste %{street}" ],
    descriptions: [ "Od rána husto sneží a cesta na ulici %{street} stále nie je odhrnutá ani posypaná. Autobusy tu nemôžu prejsť." ] },
  { category: "Komunikácie", subcategory: "cesta", subtype: "rozkopaná", photo: "road",
    titles: [ "Rozkopaná cesta po výkopových prácach" ],
    descriptions: [ "Po výkopových prácach na ulici %{street} ostala cesta rozkopaná a zasypaná len štrkom. Práce sú dávno ukončené, ale povrch nikto neopravil." ] },
  { category: "Komunikácie", subcategory: "chodník", subtype: "poškodená dlažba", photo: "road",
    titles: [ "Uvoľnená dlažba na chodníku %{street}", "Poškodená dlažba pred vchodom do obchodu" ],
    descriptions: [ "Dlaždice na chodníku sú uvoľnené a vytŕčajú, hrozí zakopnutie hlavne pre seniorov a ľudí s kočíkom." ] },
  { category: "Komunikácie", subcategory: "chodník", subtype: "bariéra na chodníku", photo: "road",
    titles: [ "Bariéra na chodníku pre vozíčkarov", "Chýba bezbariérový nájazd na chodník" ],
    descriptions: [ "Na rohu ulice %{street} chýba znížený obrubník, s kočíkom alebo invalidným vozíkom sa na chodník nedá dostať." ] },
  { category: "Komunikácie", subcategory: "chodník", subtype: "neodhrnutý", photo: "road",
    titles: [ "Zľadovatený a neodhrnutý chodník" ],
    descriptions: [ "Chodník na ulici %{street} je pokrytý ľadom a snehom, ľudia chodia po ceste. Prosím o odhrnutie a posyp." ] },
  { category: "Komunikácie", subcategory: "cyklotrasa", subtype: "chýbajúca", photo: "road",
    titles: [ "Chýba prepojenie cyklotrasy", "Cyklotrasa náhle končí na ulici %{street}" ],
    descriptions: [ "Cyklotrasa končí uprostred križovatky a cyklisti musia pokračovať v hustej doprave. Chýba bezpečné prepojenie." ] },
  { category: "Komunikácie", subcategory: "schody", subtype: "poškodená", photo: "road",
    titles: [ "Poškodené schody k zastávke MHD" ],
    descriptions: [ "Betónové schody pri ulici %{street} sú popraskané, chýbajú kusy schodov a zábradlie sa kýve." ] },
  { category: "Osvetlenie", subcategory: "osvetlenie", subtype: "nefunknčné", photo: "furniture",
    titles: [ "Nesvieti verejné osvetlenie na ulici %{street}", "Nefunkčná lampa pri prechode pre chodcov" ],
    descriptions: [ "Už niekoľko dní nesvieti pouličná lampa, celý úsek ulice %{street} je večer úplne tmavý a nebezpečný pre chodcov." ] },
  { category: "Osvetlenie", subcategory: "osvetlenie", subtype: "poškodený stĺp", photo: "furniture",
    titles: [ "Naklonený stĺp verejného osvetlenia" ],
    descriptions: [ "Stĺp osvetlenia na ulici %{street} je po nehode naklonený a hrozí jeho pád na chodník." ] },
  { category: "Verejný poriadok", subcategory: "reklama", subtype: "nelegálna reklama", photo: "graffiti",
    titles: [ "Nelegálne billboardy pri ceste", "Plagáty nalepené na zastávke" ],
    descriptions: [ "Na ulici %{street} pribudli reklamné plagáty a billboardy bez povolenia. Zakrývajú výhľad vodičom." ] },
  { category: "Verejný poriadok", subcategory: "neporiadok vo verejnom priestranstve", subtype: "neporiadok vo verejnom priestore", photo: "graffiti",
    titles: [ "Neporiadok a odpadky na námestí", "Pohodené odpadky pri lavičkách" ],
    descriptions: [ "Okolo lavičiek na ulici %{street} sa hromadia odpadky, fľaše a ohorky. Koše sú preplnené." ] },
  { category: "Verejný poriadok", subcategory: "neporiadok vo verejnom priestranstve", subtype: "neodpratané lístie", photo: "greenery",
    titles: [ "Neodpratané lístie na chodníku" ],
    descriptions: [ "Mokré lístie na chodníku pri ulici %{street} je šmykľavé, nikto ho neodpratáva už niekoľko týždňov." ] },
  { category: "Verejný poriadok", subcategory: "vandalizmus", subtype: "rušenie nočného pokoja", photo: "graffiti",
    titles: [ "Rušenie nočného pokoja v parku" ],
    descriptions: [ "Každý víkend v noci sa v parku pri ulici %{street} schádzajú skupiny ľudí, hrá hlasná hudba a ráno je všade neporiadok." ] },
  { category: "Verejný poriadok", subcategory: "iné", subtype: nil, photo: "graffiti",
    titles: [ "Graffiti na fasáde školy", "Posprejovaná zastávka MHD" ],
    descriptions: [ "Niekto posprejoval fasádu budovy na ulici %{street} graffiti. Prosím o odstránenie a prípadne kamerový dohľad." ] },
  { category: "Zeleň a znečisťovanie", subcategory: "kosenie", subtype: "nepravidelne", photo: "greenery",
    titles: [ "Nepokosená tráva na sídlisku", "Tráva pri ihrisku po pás" ],
    descriptions: [ "Tráva na ulici %{street} nebola kosená celé leto, je vysoká po pás a sú v nej kliešte." ] },
  { category: "Zeleň a znečisťovanie", subcategory: "strom", subtype: "suchý", photo: "greenery",
    titles: [ "Suchý strom hrozí pádom", "Uschnutý strom pri detskom ihrisku" ],
    descriptions: [ "Strom pri ulici %{street} je úplne suchý, pri silnejšom vetre z neho padajú konáre. Hrozí pád na chodcov alebo autá." ] },
  { category: "Zeleň a znečisťovanie", subcategory: "strom", subtype: "zlomený konár", photo: "greenery",
    titles: [ "Zlomený konár visí nad chodníkom" ],
    descriptions: [ "Po búrke ostal na strome pri ulici %{street} zlomený konár, ktorý visí priamo nad chodníkom." ] },
  { category: "Zeleň a znečisťovanie", subcategory: "krík", subtype: "neorezaný", photo: "greenery",
    titles: [ "Prerastené kríky zakrývajú výhľad na križovatke" ],
    descriptions: [ "Kríky na rohu ulice %{street} sú prerastené a vodiči nevidia prichádzajúce autá ani chodcov." ] },
  { category: "Zvieratá", subcategory: "zver v meste", subtype: "premnožené hlodavce", photo: "greenery",
    titles: [ "Potkany pri kontajneroch" ],
    descriptions: [ "Pri kontajnerovom stanovišti na ulici %{street} sa premnožili potkany, behajú aj cez deň. Treba deratizáciu." ] },
  { category: "Zvieratá", subcategory: "mŕtvy živočích", subtype: nil, photo: "road",
    titles: [ "Mŕtva srna pri ceste", "Uhynutá labuť na brehu" ],
    descriptions: [ "Pri ceste na ulici %{street} leží mŕtve zviera, prosím o odstránenie kadáveru." ] },
  { category: "Skládky a vraky", subcategory: "nelegálne skládky", subtype: nil, photo: "greenery",
    titles: [ "Čierna skládka stavebného odpadu", "Vyhodené pneumatiky a nábytok v lesíku" ],
    descriptions: [ "Za garážami na ulici %{street} vznikla čierna skládka, niekto tam vyváža stavebný odpad, staré pneumatiky a nábytok." ] },
  { category: "Skládky a vraky", subcategory: "vraky motorových vozidiel", subtype: nil, photo: "road",
    titles: [ "Vrak auta bez ŠPZ na parkovisku", "Odstavené auto roky blokuje parkovanie" ],
    descriptions: [ "Na parkovisku na ulici %{street} stojí už viac ako rok vrak auta bez evidenčných čísel, má prázdne pneumatiky a rozbité okná." ] },
  { category: "Skládky a vraky", subcategory: "kontajnerové stanovištia", subtype: "chýbajúce", photo: "furniture",
    titles: [ "Chýba kontajner na triedený odpad" ],
    descriptions: [ "Na ulici %{street} nie je žiadny kontajner na plasty a papier, najbližší je vzdialený pol kilometra." ] },
  { category: "Ostatné", subcategory: "iné", subtype: nil, photo: "furniture",
    titles: [ "Rozbitá lavička v parku", "Poškodené detské ihrisko" ],
    descriptions: [ "Lavička na ulici %{street} má zlomené dosky, na ihrisku je rozbitá hojdačka a trčia z nej skrutky." ] }
].freeze

QUESTION_TEMPLATES = [
  { category: "Komunikácie", subcategory: "cesta", title: "Kedy sa bude opravovať cesta %{street}?",
    description: "Chcel by som sa opýtať, či je v pláne rekonštrukcia cesty na ulici %{street} a kedy sa s ňou začne." },
  { category: "Zeleň a znečisťovanie", subcategory: "strom", title: "Prečo sa rúbu stromy na ulici %{street}?",
    description: "Dnes ráno začali pracovníci rúbať zdravé stromy na ulici %{street}. Existuje na to povolenie a bude náhradná výsadba?" },
  { category: "Skládky a vraky", subcategory: "kontajnerové stanovištia", title: "Kto zodpovedá za kontajnerové stanovište?",
    description: "Na koho sa môžem obrátiť ohľadom stavu kontajnerového stanovišťa na ulici %{street}? Je stále preplnené." }
].freeze

PRAISE_TEMPLATES = [
  { title: "Ďakujeme za nový chodník na ulici %{street}", description: "Chcem poďakovať za rýchlu opravu chodníka na ulici %{street}, konečne sa dá prejsť s kočíkom." },
  { title: "Pochvala za vyčistený park", description: "Park pri ulici %{street} je po jarnom upratovaní krásne čistý, ďakujeme všetkým, čo sa o to postarali." },
  { title: "Vďaka za nové lavičky", description: "Nové lavičky a koše na ulici %{street} sú skvelé, seniori si konečne majú kde sadnúť." }
].freeze

COMMENT_TEXTS = [
  "Potvrdzujem, dnes ráno som tam išiel a stav je stále rovnaký.",
  "Tento problém tu je už roky, dúfam, že sa konečne niečo pohne.",
  "Ďakujem za nahlásenie, tiež ma to trápi.",
  "Včera sa tam kvôli tomu skoro stala nehoda.",
  "Vyzerá to, že sa na tom už pracuje, videl som tam pracovníkov.",
  "Situácia sa ešte zhoršila, pribudli ďalšie škody.",
  "Je to nebezpečné hlavne pre deti, ktoré tade chodia do školy."
].freeze

# [state key, weight, resolution process?]
ISSUE_STATE_WEIGHTS = [
  [ "waiting", 8, false ],
  [ "waiting_for_author", 3, false ],
  [ "rejected", 5, false ],
  [ "duplicate", 3, false ],
  [ "sent_to_responsible", 15, true ],
  [ "in_progress", 15, true ],
  [ "referred", 5, true ],
  [ "resolved", 20, true ],
  [ "resolved_private", 2, true ],
  [ "unresolved", 8, true ],
  [ "marked_as_resolved", 5, true ],
  [ "closed", 6, true ],
  [ "archived", 5, true ]
].freeze

SPECIALIZED_RESPONSIBLE_SUBJECTS = {
  "Komunikácie" => "Dopravný podnik Bratislava, a.s.",
  "Zeleň a znečisťovanie" => "Mestské lesy v Bratislave",
  "Skládky a vraky" => "OLO Bratislava",
  "Verejný poriadok" => "Mestská polícia hlavného mesta SR Bratislavy"
}.freeze

if Issue.exists?
  puts "Issues already exist, skipping issue seeds (use db:seed:replant to reseed)"
else
  rng = Random.new(2024)
  pick = ->(items) { items[rng.rand(items.size)] }
  weighted_pick = ->(items) do
    target = rng.rand(items.sum { |item| item[1] })
    items.find { |item| (target -= item[1]) < 0 }
  end

  states = Issues::State.all.index_by(&:key)
  citizens = User::Citizen.where(anonymous: false).where.not(email: "novy@example.com").to_a
  photos = Dir[Rails.root.join("db/seeds/fixtures/issue_photos/*.jpg")].index_by { |path| File.basename(path, ".jpg") }

  categories = Issues::Category.non_legacy.includes(subcategories: :subtypes).index_by(&:name)
  find_classification = ->(category_name, subcategory_name, subtype_name) do
    category = categories.fetch(category_name)
    subcategory = category.subcategories.find { |s| s.name == subcategory_name } or raise "Unknown subcategory #{subcategory_name}"
    subtype = subtype_name && (subcategory.subtypes.find { |s| s.name == subtype_name } or raise "Unknown subtype #{subtype_name}")
    [ category, subcategory, subtype ]
  end

  # Flatten municipalities to places issues can be reported at; Bratislava gets ~60% of issues
  places = DEV_SEED_MUNICIPALITIES.flat_map do |data|
    municipality = Municipality.find_by!(name: data[:name])
    if data[:districts]
      data[:districts].map do |district_data|
        district = municipality.municipality_districts.find_by!(name: district_data[:name])
        responsible_subject = ResponsibleSubject.find_by(subject_name: "MÚ #{district.name}")
        [ { municipality:, district:, region: data[:region], responsible_subject:, **district_data.slice(:latitude, :longitude, :streets) }, 60.0 / data[:districts].size ]
      end
    else
      responsible_subject = ResponsibleSubject.find_by(municipality: municipality, municipality_district: nil)
      [ [ { municipality:, district: nil, region: data[:region], responsible_subject:, **data.slice(:latitude, :longitude, :streets) }, 8 ] ]
    end
  end
  bratislava_rs = ResponsibleSubject.find_by!(subject_name: "Hlavné mesto SR Bratislava")

  count = ENV.fetch("SEED_ISSUES_COUNT", 300).to_i
  resolution_external_id = 900_000

  count.times do |n|
    print "." if (n + 1) % 25 == 0
    place = weighted_pick.(places).first
    street = pick.(place[:streets])
    issue_type = weighted_pick.([ [ :issue, 80 ], [ :question, 12 ], [ :praise, 8 ] ]).first

    case issue_type
    when :issue
      template = pick.(ISSUE_TEMPLATES)
      title = pick.(template[:titles])
      description = pick.(template[:descriptions])
      category, subcategory, subtype = find_classification.(template[:category], template[:subcategory], template[:subtype])
      photo = template[:photo]
      state_key, _, resolution_process = weighted_pick.(ISSUE_STATE_WEIGHTS)
    when :question
      template = pick.(QUESTION_TEMPLATES)
      title, description = template.values_at(:title, :description)
      category, subcategory, subtype = find_classification.(template[:category], template[:subcategory], nil)
      photo = pick.(photos.keys)
      state_key, _, resolution_process = weighted_pick.(ISSUE_STATE_WEIGHTS.reject { |key, *| key == "archived" })
    when :praise
      template = pick.(PRAISE_TEMPLATES)
      title, description = template.values_at(:title, :description)
      category = subcategory = subtype = nil
      photo = pick.(photos.keys)
      state_key = weighted_pick.([ [ "resolved", 8 ], [ "waiting", 1 ], [ "rejected", 1 ] ]).first
      resolution_process = false
    end

    archived = state_key == "archived"
    # skew towards recent issues, archived ones are old
    days_ago = archived ? 800 + rng.rand(700) : (rng.rand**2 * 730).to_i
    created_at = days_ago.days.ago - rng.rand(86_400).seconds
    resolution_started_at = resolution_process ? [ created_at + rng.rand(1..5).days, Time.current ].min : nil

    responsible_subject = if state_key == "waiting" || issue_type == :praise
      nil
    elsif place[:municipality].name == "Bratislava" && rng.rand < 0.3
      rng.rand < 0.7 && SPECIALIZED_RESPONSIBLE_SUBJECTS[category&.name] ? ResponsibleSubject.find_by!(subject_name: SPECIALIZED_RESPONSIBLE_SUBJECTS[category.name]) : bratislava_rs
    else
      place[:responsible_subject]
    end

    author = pick.(citizens)

    issue = Issue.new(
      issue_type: issue_type,
      title: format(title, street: street),
      description: format(description, street: street),
      author: author,
      anonymous: rng.rand < 0.1,
      category: category,
      subcategory: subcategory,
      subtype: subtype,
      state: states.fetch(state_key),
      archived_state: archived ? states.fetch(pick.(%w[resolved unresolved closed])) : nil,
      municipality: place[:municipality],
      municipality_district: place[:district],
      responsible_subject: responsible_subject,
      latitude: place[:latitude] + (rng.rand - 0.5) * 0.016,
      longitude: place[:longitude] + (rng.rand - 0.5) * 0.024,
      address_street: street,
      address_house_number: rng.rand(1..120).to_s,
      address_city: place[:municipality].name,
      address_municipality: place[:district]&.name || place[:municipality].name,
      address_suburb: place[:district]&.name,
      address_region: place[:region],
      address_country: "Slovensko",
      address_country_code: "sk",
      public: true,
      resolution_external_id: resolution_process ? (resolution_external_id += 1) : nil,
      resolution_started_at: resolution_started_at,
      created_at: created_at,
      updated_at: resolution_started_at || created_at
    )
    issue.photos.attach(io: File.open(photos.fetch(photo)), filename: "#{photo}.jpg", content_type: "image/jpeg")
    issue.save!

    IssueSubscription.create!(issue: issue, subscriber: author)

    next unless issue.publicly_visible? && issue.issue_type != "praise"

    citizens.sample(rng.rand(0..8), random: rng).each { |user| IssueLike.create!(issue: issue, user: user) }

    next unless issue.resolution_process? && rng.rand < 0.5

    rng.rand(1..4).times do |i|
      commented_at = [ resolution_started_at + (i + 1) * rng.rand(1..72).hours, Time.current ].min
      comment = Issues::UserComment.new(text: pick.(COMMENT_TEXTS), user_author: pick.(citizens), created_at: commented_at, updated_at: commented_at)
      comment.build_activity(issue: issue, type: Issues::CommentActivity, created_at: commented_at, updated_at: commented_at)
      comment.save!
    end
  end

  User.find_each(&:recalculate_computed_fields)
  puts "\nSeeded #{count} issues"
end
