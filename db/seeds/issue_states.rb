[
  {
    name: "Zaslaný zodpovednému",
    key: "sent_to_responsible"
  },
  {
    name: "Odstúpený",
    key: "referred"
  },
  {
    name: "Čakajúci",
    key: "waiting"
  },
  {
    name: "Vyriešený",
    key: "resolved"
  },
  {
    name: "Vyriešený (skrytý)",
    key: "resolved_private"
  },
  {
    name: "Neriešený",
    key: "unresolved"
  },
  {
    name: "V riešení",
    key: "in_progress"
  },
  {
    name: "Zamietnutý",
    key: "rejected"
  },
  {
    name: "Uzavretý",
    key: "closed"
  },
  {
    name: "Označený za vyriešený",
    key: "marked_as_resolved"
  },
  {
    name: "Duplicitný",
    key: "duplicate"
  }
].each do |state_data|
  Issues::State.find_or_create_by!(key: state_data[:key]).tap do |issues_state|
    issues_state.update(name: state_data[:name])
  end
end
