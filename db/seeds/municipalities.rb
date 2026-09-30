# Municipalities and Bratislava city districts with approximate centers and a few
# real street names, so seeded issues land on sensible places on the map.

DEV_SEED_MUNICIPALITIES = [
  {
    name: "Bratislava", region: "Bratislavský kraj", category: :regional_capital, municipality_type: :huge,
    population: 475_503, latitude: 48.1486, longitude: 17.1077,
    districts: [
      { name: "Staré Mesto", latitude: 48.1440, longitude: 17.1090, streets: [ "Obchodná", "Michalská", "Panská", "Palisády", "Štúrova", "Hlavné námestie" ] },
      { name: "Ružinov", latitude: 48.1580, longitude: 17.1650, streets: [ "Bajkalská", "Trnavská cesta", "Ružinovská", "Tomášikova", "Prievozská" ] },
      { name: "Vrakuňa", latitude: 48.1290, longitude: 17.2170, streets: [ "Hradská", "Kaštieľska", "Popradská" ] },
      { name: "Podunajské Biskupice", latitude: 48.1200, longitude: 17.2300, streets: [ "Biskupická", "Kazanská", "Uzbecká" ] },
      { name: "Nové Mesto", latitude: 48.1720, longitude: 17.1250, streets: [ "Račianska", "Vajnorská", "Pionierska", "Škultétyho", "Kukučínova" ] },
      { name: "Rača", latitude: 48.2110, longitude: 17.1510, streets: [ "Alstrova", "Detvianska", "Kadnárova" ] },
      { name: "Vajnory", latitude: 48.2060, longitude: 17.2070, streets: [ "Roľnícka", "Baničova", "Koniarkova" ] },
      { name: "Karlova Ves", latitude: 48.1590, longitude: 17.0550, streets: [ "Karloveská", "Pribišova", "Líščie údolie", "Majerníkova" ] },
      { name: "Dúbravka", latitude: 48.1850, longitude: 17.0360, streets: [ "Saratovská", "Pri kríži", "Bagarova", "Harmincova" ] },
      { name: "Lamač", latitude: 48.1940, longitude: 17.0490, streets: [ "Hodonínska", "Malokarpatské námestie" ] },
      { name: "Devín", latitude: 48.1740, longitude: 16.9850, streets: [ "Kremeľská", "Hradná" ] },
      { name: "Devínska Nová Ves", latitude: 48.2100, longitude: 16.9760, streets: [ "Eisnerova", "Istrijská", "Na Grbe" ] },
      { name: "Záhorská Bystrica", latitude: 48.2370, longitude: 17.0460, streets: [ "Brečtanová", "Gbelská" ] },
      { name: "Petržalka", latitude: 48.1210, longitude: 17.1100, streets: [ "Rusovská cesta", "Romanova", "Jiráskova", "Einsteinova", "Budatínska" ] },
      { name: "Jarovce", latitude: 48.0710, longitude: 17.1070, streets: [ "Palmová", "Jánošíkova" ] },
      { name: "Rusovce", latitude: 48.0540, longitude: 17.1480, streets: [ "Balkánska", "Maďarská" ] },
      { name: "Čunovo", latitude: 48.0310, longitude: 17.2000, streets: [ "Hraničiarska", "Schengenská" ] }
    ]
  },
  { name: "Banská Bystrica", region: "Banskobystrický kraj", category: :regional_capital, municipality_type: :other,
    population: 76_018, latitude: 48.7363, longitude: 19.1462, streets: [ "Námestie SNP", "Horná", "Švermova", "Moyzesova" ] },
  { name: "Trnava", region: "Trnavský kraj", category: :regional_capital, municipality_type: :other,
    population: 63_803, latitude: 48.3774, longitude: 17.5883, streets: [ "Hlavná", "Hospodárska", "Štefánikova", "Coburgova" ] },
  { name: "Nitra", region: "Nitriansky kraj", category: :regional_capital, municipality_type: :other,
    population: 76_655, latitude: 48.3069, longitude: 18.0864, streets: [ "Štefánikova trieda", "Farská", "Akademická", "Chrenovská" ] },
  { name: "Malacky", region: "Bratislavský kraj", category: :town, municipality_type: :other,
    population: 18_210, latitude: 48.4361, longitude: 17.0217, streets: [ "Záhorácka", "Kollárova", "Pezinská" ] },
  { name: "Pezinok", region: "Bratislavský kraj", category: :town, municipality_type: :other,
    population: 23_669, latitude: 48.2894, longitude: 17.2667, streets: [ "Holubyho", "Myslenická", "Moyzesova" ] }
].freeze

DEV_SEED_MUNICIPALITIES.each do |data|
  municipality = Municipality.find_or_initialize_by(name: data[:name])
  municipality.assign_attributes(
    latitude: data[:latitude],
    longitude: data[:longitude],
    population: data[:population],
    category: data[:category],
    municipality_type: data[:municipality_type],
    has_municipality_districts: data[:districts].present?,
    active: true,
    active_on_old_portal: false,
    archived: false,
    aliases: [ data[:name], data[:name].parameterize ]
  )
  municipality.save!

  Array(data[:districts]).each do |district_data|
    district = MunicipalityDistrict.find_or_initialize_by(municipality: municipality, name: district_data[:name])
    district.assign_attributes(
      active: true,
      archived: false,
      aliases: [ district_data[:name], district_data[:name].parameterize ]
    )
    district.save!
  end
end
