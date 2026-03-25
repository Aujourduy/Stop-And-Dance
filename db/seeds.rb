# Story 1.2: Realistic Seed Data for UI Development
# This file is idempotent - running rails db:seed multiple times won't create duplicates

puts "🌱 Seeding database with realistic data..."

# 1. Create ScrapedUrls first (needed for professor associations)
puts "\n📊 Creating scraped URLs..."

scraped_urls_data = [
  { url: "https://example.com/sophie-marchand", notes_correctrices: "Site personnel - scraping actif" },
  { url: "https://example.com/jean-luc-dubois", notes_correctrices: "Page Facebook - scraping manuel" },
  { url: "https://example.com/marie-fontaine", notes_correctrices: nil },
  { url: "https://example.com/pierre-lefebvre", notes_correctrices: "Agenda Google public" },
  { url: "https://example.com/events/ci-paris", notes_correctrices: "Source collective - plusieurs profs" }
]

scraped_urls = scraped_urls_data.map do |data|
  ScrapedUrl.find_or_create_by!(url: data[:url]) do |su|
    su.notes_correctrices = data[:notes_correctrices]
    su.statut_scraping = 'actif'
  end
end

puts "✓ Created #{scraped_urls.count} scraped URLs"

# 2. Create Professors
puts "\n👤 Creating professors..."

professors_data = [
  {
    email: "sophie.marchand@example.com",
    site_web: "https://example.com/sophie-marchand",
    avatar_url: "https://i.pravatar.cc/300?img=1",
    bio: "Danseuse et chorégraphe spécialisée en Contact Improvisation depuis 15 ans. J'explore les liens entre corps, gravité et relation à l'autre dans mes ateliers.",
    scraped_url_indices: [0]
  },
  {
    email: "jeanluc.dubois@example.com",
    site_web: "https://example.com/jean-luc-dubois",
    avatar_url: "https://i.pravatar.cc/300?img=2",
    bio: "Praticien certifié en Danse des 5 Rythmes (Gabrielle Roth). J'accompagne les danseurs vers une exploration authentique du mouvement spontané et de l'expression créative.",
    scraped_url_indices: [1]
  },
  {
    email: "marie.fontaine@example.com",
    site_web: "https://example.com/marie-fontaine",
    avatar_url: "https://i.pravatar.cc/300?img=3",
    bio: "Somaticienne formée en Authentic Movement et Body-Mind Centering. Je propose des espaces d'exploration du mouvement conscient et de l'écoute intérieure.",
    scraped_url_indices: [2]
  },
  {
    email: "pierre.lefebvre@example.com",
    site_web: "https://example.com/pierre-lefebvre",
    avatar_url: "https://i.pravatar.cc/300?img=4",
    bio: "Artiste butô et performeur. Mon travail explore la lenteur, la transformation et les états du corps dans l'immobilité et le mouvement minimal.",
    scraped_url_indices: [3]
  }
]

professors = professors_data.map do |data|
  prof = Professor.find_or_create_by!(email: data[:email]) do |p|
    p.site_web = data[:site_web]
    p.avatar_url = data[:avatar_url]
    p.bio = data[:bio]
  end

  # Associate with scraped URLs
  data[:scraped_url_indices].each do |idx|
    ProfessorScrapedUrl.find_or_create_by!(
      professor: prof,
      scraped_url: scraped_urls[idx]
    )
  end

  prof
end

puts "✓ Created #{professors.count} professors"

# 3. Create FUTURE Events (15-20 events)
puts "\n📅 Creating future events..."

future_events_data = [
  # Ateliers Contact Improvisation
  { titre: "Atelier Contact Improvisation", type_event: :atelier, tags: ["Contact Improvisation"],
    date_offset_days: 2, duree_heures: 2, lieu: "Paris", prix_normal: 20, gratuit: false, professor_idx: 0, scraped_url_idx: 0 },
  { titre: "Contact Impro - Session du soir", type_event: :atelier, tags: ["Contact Improvisation"],
    date_offset_days: 9, duree_heures: 2.5, lieu: "Lyon", prix_normal: 18, gratuit: false, professor_idx: 0, scraped_url_idx: 0 },
  { titre: "CI - Jam ouverte à tous", type_event: :atelier, tags: ["Contact Improvisation"],
    date_offset_days: 16, duree_heures: 3, lieu: "Marseille", prix_normal: 0, gratuit: true, professor_idx: 0, scraped_url_idx: nil },

  # Danse des 5 Rythmes
  { titre: "Danse des 5 Rythmes - Exploration", type_event: :atelier, tags: ["Danse des 5 Rythmes"],
    date_offset_days: 5, duree_heures: 2, lieu: "Bordeaux", prix_normal: 25, gratuit: false, professor_idx: 1, scraped_url_idx: 1 },
  { titre: "5 Rythmes - Vagues du matin", type_event: :atelier, tags: ["Danse des 5 Rythmes"],
    date_offset_days: 12, duree_heures: 1.5, lieu: "Toulouse", prix_normal: 15, gratuit: false, professor_idx: 1, scraped_url_idx: 1 },
  { titre: "Stage 5 Rythmes - Week-end intensif", type_event: :stage, tags: ["Danse des 5 Rythmes"],
    date_offset_days: 30, duree_heures: 12, lieu: "Nantes", prix_normal: 150, prix_reduit: 120, gratuit: false, professor_idx: 1, scraped_url_idx: 1 },

  # Authentic Movement
  { titre: "Exploration Authentic Movement", type_event: :atelier, tags: ["Authentic Movement"],
    date_offset_days: 7, duree_heures: 2, lieu: "Paris", prix_normal: 22, gratuit: false, professor_idx: 2, scraped_url_idx: 2 },
  { titre: "Authentic Movement - Cercle de pratique", type_event: :atelier, tags: ["Authentic Movement"],
    date_offset_days: 21, duree_heures: 3, lieu: "Lyon", prix_normal: 0, gratuit: true, professor_idx: 2, scraped_url_idx: nil },
  { titre: "Stage Authentic Movement & Voix", type_event: :stage, tags: ["Authentic Movement"],
    date_offset_days: 45, duree_heures: 16, lieu: "Bordeaux", prix_normal: 180, prix_reduit: 150, gratuit: false, professor_idx: 2, scraped_url_idx: 2 },

  # Body-Mind Centering
  { titre: "Atelier Body-Mind Centering - Initiation", type_event: :atelier, tags: ["Body-Mind Centering"],
    date_offset_days: 10, duree_heures: 2.5, lieu: "Paris", prix_normal: 30, gratuit: false, professor_idx: 2, scraped_url_idx: 2 },
  { titre: "BMC - Systèmes du corps", type_event: :atelier, tags: ["Body-Mind Centering"],
    date_offset_days: 24, duree_heures: 3, lieu: "Marseille", prix_normal: 35, gratuit: false, professor_idx: 2, scraped_url_idx: 2 },

  # Danse Butô
  { titre: "Introduction à la Danse Butô", type_event: :atelier, tags: ["Danse Butô"],
    date_offset_days: 14, duree_heures: 2, lieu: "Lyon", prix_normal: 25, gratuit: false, professor_idx: 3, scraped_url_idx: 3 },
  { titre: "Butô - L'art de la lenteur", type_event: :atelier, tags: ["Danse Butô"],
    date_offset_days: 28, duree_heures: 3, lieu: "Paris", prix_normal: 28, gratuit: false, professor_idx: 3, scraped_url_idx: 3 },
  { titre: "Stage Butô - Week-end immersif", type_event: :stage, tags: ["Danse Butô"],
    date_offset_days: 60, duree_heures: 14, lieu: "Toulouse", prix_normal: 200, prix_reduit: 160, gratuit: false, professor_idx: 3, scraped_url_idx: 3 },

  # Événements en ligne
  { titre: "Atelier Contact Impro en ligne", type_event: :atelier, tags: ["Contact Improvisation"],
    date_offset_days: 4, duree_heures: 1.5, lieu: "En ligne", prix_normal: 12, gratuit: false, en_ligne: true, en_presentiel: false, professor_idx: 0, scraped_url_idx: 0 },
  { titre: "5 Rythmes en ligne - Session du soir", type_event: :atelier, tags: ["Danse des 5 Rythmes"],
    date_offset_days: 11, duree_heures: 1, lieu: "En ligne", prix_normal: 10, gratuit: false, en_ligne: true, en_presentiel: false, professor_idx: 1, scraped_url_idx: 1 },

  # Mix tags
  { titre: "Contact Impro & 5 Rythmes - Fusion", type_event: :atelier, tags: ["Contact Improvisation", "Danse des 5 Rythmes"],
    date_offset_days: 35, duree_heures: 3, lieu: "Nantes", prix_normal: 30, gratuit: false, professor_idx: 0, scraped_url_idx: 0 },
  { titre: "Stage Somatique - BMC & Authentic Movement", type_event: :stage, tags: ["Body-Mind Centering", "Authentic Movement"],
    date_offset_days: 75, duree_heures: 20, lieu: "Bordeaux", prix_normal: 250, prix_reduit: 200, gratuit: false, professor_idx: 2, scraped_url_idx: 2 },

  # Gratuit events
  { titre: "Jam Contact Improvisation gratuite", type_event: :atelier, tags: ["Contact Improvisation"],
    date_offset_days: 18, duree_heures: 2, lieu: "Paris", prix_normal: 0, gratuit: true, professor_idx: 0, scraped_url_idx: nil },
  { titre: "Rencontre Danse libre - Gratuit", type_event: :atelier, tags: ["Danse des 5 Rythmes"],
    date_offset_days: 40, duree_heures: 2, lieu: "Lyon", prix_normal: 0, gratuit: true, professor_idx: 1, scraped_url_idx: nil }
]

future_events = future_events_data.map do |data|
  base_time = Time.zone.now.beginning_of_day + 19.hours # 19h
  date_debut = base_time + data[:date_offset_days].days
  date_fin = date_debut + (data[:duree_heures] * 60).minutes

  Event.find_or_create_by!(
    titre: data[:titre],
    date_debut: date_debut,
    lieu: data[:lieu]
  ) do |e|
    e.description = "#{data[:titre]} avec #{professors[data[:professor_idx]].email.split('@').first.titleize}. Une exploration profonde et bienveillante du mouvement."
    e.tags = data[:tags]
    e.date_fin = date_fin
    e.type_event = data[:type_event]
    e.prix_normal = data[:prix_normal]
    e.prix_reduit = data[:prix_reduit]
    e.gratuit = data[:gratuit]
    e.en_ligne = data[:en_ligne] || false
    e.en_presentiel = data[:en_presentiel] || true
    e.professor = professors[data[:professor_idx]]
    e.scraped_url = data[:scraped_url_idx].nil? ? nil : scraped_urls[data[:scraped_url_idx]]
    e.adresse_complete = data[:lieu] == "En ligne" ? nil : "#{rand(1..150)} Rue de la Danse, #{data[:lieu]}"
  end
end

puts "✓ Created #{future_events.count} future events"

# 4. Create PAST Events (5-6 events)
puts "\n🕐 Creating past events..."

past_events_data = [
  { titre: "Atelier Contact Improvisation (passé)", type_event: :atelier, tags: ["Contact Improvisation"],
    date_offset_days: -45, duree_heures: 2, lieu: "Paris", prix_normal: 20, gratuit: false, professor_idx: 0 },
  { titre: "Stage 5 Rythmes (passé)", type_event: :stage, tags: ["Danse des 5 Rythmes"],
    date_offset_days: -30, duree_heures: 12, lieu: "Lyon", prix_normal: 140, gratuit: false, professor_idx: 1 },
  { titre: "Exploration Authentic Movement (passé)", type_event: :atelier, tags: ["Authentic Movement"],
    date_offset_days: -15, duree_heures: 2.5, lieu: "Marseille", prix_normal: 22, gratuit: false, professor_idx: 2 },
  { titre: "Butô - Workshop (passé)", type_event: :atelier, tags: ["Danse Butô"],
    date_offset_days: -7, duree_heures: 3, lieu: "Bordeaux", prix_normal: 25, gratuit: false, professor_idx: 3 },
  { titre: "Jam gratuite (passé)", type_event: :atelier, tags: ["Contact Improvisation"],
    date_offset_days: -3, duree_heures: 2, lieu: "Toulouse", prix_normal: 0, gratuit: true, professor_idx: 0 },
  { titre: "5 Rythmes en ligne (passé)", type_event: :atelier, tags: ["Danse des 5 Rythmes"],
    date_offset_days: -1, duree_heures: 1.5, lieu: "En ligne", prix_normal: 12, gratuit: false, en_ligne: true, en_presentiel: false, professor_idx: 1 }
]

past_events = past_events_data.map do |data|
  base_time = Time.zone.now.beginning_of_day + 19.hours # 19h
  date_debut = base_time + data[:date_offset_days].days
  date_fin = date_debut + (data[:duree_heures] * 60).minutes

  Event.find_or_create_by!(
    titre: data[:titre],
    date_debut: date_debut,
    lieu: data[:lieu]
  ) do |e|
    e.description = "#{data[:titre]} - événement passé."
    e.tags = data[:tags]
    e.date_fin = date_fin
    e.type_event = data[:type_event]
    e.prix_normal = data[:prix_normal]
    e.prix_reduit = data[:prix_reduit]
    e.gratuit = data[:gratuit]
    e.en_ligne = data[:en_ligne] || false
    e.en_presentiel = data[:en_presentiel] || true
    e.professor = professors[data[:professor_idx]]
    e.scraped_url = nil # Past events sans source
    e.adresse_complete = data[:lieu] == "En ligne" ? nil : "#{rand(1..150)} Rue Historique, #{data[:lieu]}"
  end
end

puts "✓ Created #{past_events.count} past events"

# 5. Summary
puts "\n✅ Seed completed!"
puts "   📊 #{ScrapedUrl.count} scraped URLs"
puts "   👤 #{Professor.count} professors"
puts "   📅 #{Event.count} total events"
puts "   🔮 #{Event.futurs.count} future events (visible)"
puts "   🕐 #{Event.count - Event.futurs.count} past events (hidden by Event.futurs scope)"
