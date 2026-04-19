# Sanity checks sémantiques sur les données scrapées.
# Lance : bin/rails runner script/data-sanity.rb
#
# Détecte les anomalies invisibles aux tests syntaxiques (existence, FK, 200):
# - noms de profs composites ("Marc et Peter") → signe d'un parsing raté
# - profs sans events après scraping (orphelins logiques)
# - events sur URL multi-profs où le host ne matche pas le site_web du prof
# - chaînes anormalement longues dans prof.prenom / prof.nom
# - events rattachés à un prof qui n'est pas dans scraped_url.professors

results = { ok: [], warn: [], fail: [] }

def add(results, level, section, msg)
  icon = { ok: "✅", warn: "⚠️ ", fail: "❌" }[level]
  puts "#{icon} [#{section}] #{msg}"
  results[level] << { section: section, msg: msg }
end

# 1. Noms composites
composites = Professor.where("nom LIKE ? OR prenom LIKE ? OR nom LIKE ? OR prenom LIKE ?",
                             "% et %", "% et %", "% & %", "% & %")
if composites.empty?
  add(results, :ok, "Profs composites", "Aucun nom contenant ' et ' / ' & '")
else
  composites.each do |p|
    add(results, :fail, "Profs composites",
        "##{p.id} \"#{p.prenom}\" / \"#{p.nom}\" — parsing à corriger")
  end
end

# 2. Noms anormalement longs (>40 chars prenom+nom)
too_long = Professor.all.select { |p| (p.prenom.to_s + p.nom.to_s).length > 40 }
if too_long.empty?
  add(results, :ok, "Noms longs", "Aucun prof > 40 caractères")
else
  too_long.each do |p|
    add(results, :warn, "Noms longs", "##{p.id} #{p.prenom} #{p.nom} (#{(p.prenom.to_s + p.nom.to_s).length} chars)")
  end
end

# 3. Profs orphelins (0 events, 0 URLs) — potentiels reliquats
orphans = Professor.left_joins(:events, :scraped_urls)
                   .group("professors.id")
                   .having("COUNT(DISTINCT events.id) = 0 AND COUNT(DISTINCT scraped_urls.id) = 0")
if orphans.to_a.empty?
  add(results, :ok, "Profs orphelins", "Aucun prof sans event ni URL")
else
  orphans.each { |p| add(results, :warn, "Profs orphelins", "##{p.id} #{p.prenom} #{p.nom}") }
end

# 4. Attribution suspecte : event dont le professor.site_web host ≠ scraped_url host
# Groupé par (prof, host) pour ne pas inonder quand un duo récurrent apparaît.
puts
puts "=== 4. Attribution cohérente (prof.site_web vs scraped_url host) ==="
mismatches = Hash.new(0)
Event.includes(:professor, :scraped_url).find_each do |e|
  next if e.scraped_url.nil? || e.professor.nil?
  next if e.professor.site_web.blank?

  url_host = URI(e.scraped_url.url).host rescue next
  prof_host = URI(e.professor.site_web).host rescue next
  next if url_host == prof_host

  key = [ e.professor_id, e.professor.nom, url_host ]
  mismatches[key] += 1
end

if mismatches.empty?
  add(results, :ok, "Site prof ≠ host URL", "Tous les events sont scrapés depuis le site du prof")
else
  mismatches.sort_by { |_, v| -v }.first(10).each do |(_pid, nom, host), count|
    puts "  ⚠️  #{count}x events de #{nom} scrapés depuis #{host} (son site_web est ailleurs)"
  end
  add(results, :warn, "Site prof ≠ host URL", "#{mismatches.size} combinaison(s) (prof, host) à vérifier")
end

# 5. Disproportion sur URL multi-profs : un prof concentre >90% des events
puts
puts "=== 5. Distribution events par URL ==="
ScrapedUrl.where(statut_scraping: "actif").find_each do |u|
  counts = u.events.group(:professor_id).count
  next if counts.size < 2
  total = counts.values.sum
  next if total < 5

  top_prof_id, top_count = counts.max_by { |_, v| v }
  ratio = top_count.to_f / total

  # Calculer le owner attendu (même logique que ScrapedUrl#owner_professor)
  expected_owner = u.owner_professor
  top_prof = Professor.find(top_prof_id)

  if ratio > 0.9 && expected_owner && top_prof.id != expected_owner.id
    add(results, :fail, "Distribution",
        "URL ##{u.id} (#{URI(u.url).host rescue u.url}): #{top_prof.nom}=#{top_count}/#{total} (#{(ratio*100).round}%) mais owner attendu = #{expected_owner.nom}")
  end
end

# 6. Events rattachés à un prof non listé dans scraped_url.professors
puts
puts "=== 6. Professor absent de scraped_url.professors ==="
invalid_links = 0
Event.includes(:scraped_url, :professor).find_each do |e|
  next if e.scraped_url.nil? || e.professor.nil?
  unless e.scraped_url.professors.include?(e.professor)
    invalid_links += 1
    puts "  ⚠️  Event ##{e.id} prof #{e.professor.nom} pas associé à URL ##{e.scraped_url_id}" if invalid_links <= 5
  end
end
if invalid_links == 0
  add(results, :ok, "Liens professor/URL", "Tous les events ont un prof associé à leur URL")
else
  add(results, :fail, "Liens professor/URL", "#{invalid_links} events avec prof non associé")
end

# 7. Sampling manuel : 3 events aléatoires (pour vérif visuelle)
puts
puts "=== 7. Sampling pour vérif manuelle (3 events au hasard) ==="
Event.where("date_debut_date >= ?", Date.current).order("RANDOM()").limit(3).each do |e|
  host = URI(e.scraped_url.url).host rescue "?"
  puts "  📋 Event ##{e.id} \"#{e.titre[0..60]}\""
  puts "      prof    : #{e.professor.prenom} #{e.professor.nom}"
  puts "      source  : #{e.scraped_url.url}"
  puts "      à vérifier manuellement sur : #{host}"
end

# Rapport final
puts
puts "=" * 60
total = results[:ok].size + results[:warn].size + results[:fail].size
puts "SANITY CHECK : #{results[:ok].size}/#{total} OK  |  #{results[:warn].size} warn  |  #{results[:fail].size} fail"
puts "=" * 60

exit(results[:fail].size > 0 ? 1 : 0)
