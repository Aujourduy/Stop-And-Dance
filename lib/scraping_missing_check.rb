require "open3"

class ScrapingMissingCheck
  SCREENSHOT_DIR = Rails.root.join("tmp", "scraping_missing_screenshots")
  REPORT_PATH = Rails.root.join("tmp", "scraping_missing_report.md")
  CLAUDE_CLI_PATH = "/home/dang/.local/bin/claude"

  def self.run_all
    urls = ScrapedUrl.where(statut_scraping: "actif")
                     .where.not("url LIKE ?", "%example.com%")
                     .where.not("url LIKE ?", "%localhost%")
                     .joins(:events)
                     .where("events.date_debut_date >= ?", Date.current)
                     .distinct

    FileUtils.mkdir_p(SCREENSHOT_DIR)
    results = urls.map { |su| check_one(su) }
    generate_report(results)
    results
  end

  def self.check_one(scraped_url)
    result = {
      url_id: scraped_url.id, url: scraped_url.url, nom: scraped_url.nom,
      missing_events: [], extra_info: nil, error: nil, duration_ms: 0
    }
    start = Time.current

    # Step 1: Screenshot
    screenshot_path = SCREENSHOT_DIR.join("url_#{scraped_url.id}.png").to_s
    unless take_screenshot(scraped_url.url, screenshot_path)
      result[:error] = "Screenshot failed"
      result[:duration_ms] = ((Time.current - start) * 1000).round
      return result
    end

    # Step 2: Get our events from DB
    our_events = Event.where(scraped_url: scraped_url)
                      .where("date_debut_date >= ?", Date.current)
                      .order(:date_debut_date)
                      .pluck(:titre, :date_debut_date, :heure_debut, :lieu)
                      .map { |t, d, h, l| { titre: t, date: d.to_s, heure: h&.strftime("%H:%M"), lieu: l } }

    # Step 3: Ask Claude to find events on the screenshot that we DON'T have
    claude_result = ask_claude_for_missing(screenshot_path, our_events.to_json)

    if claude_result[:error]
      result[:error] = claude_result[:error]
    else
      result[:missing_events] = claude_result[:missing_events] || []
      result[:extra_info] = claude_result[:summary]
    end

    result[:duration_ms] = ((Time.current - start) * 1000).round
    result
  rescue => e
    result[:error] = "Exception: #{e.class}: #{e.message}"
    result[:duration_ms] = ((Time.current - start) * 1000).round
    result
  end

  private

  def self.take_screenshot(url, path)
    script = <<~JS
      const { chromium } = require('playwright');
      (async () => {
        const browser = await chromium.launch();
        const page = await (await browser.newContext({ viewport: { width: 1280, height: 900 } })).newPage();
        await page.goto('#{url.gsub("'", "\\\\'")}', { waitUntil: 'domcontentloaded' });
        await page.waitForTimeout(5000);
        await page.screenshot({ path: '#{path}', fullPage: true });
        await browser.close();
      })();
    JS
    script_path = Rails.root.join("tmp", "screenshot_missing.js").to_s
    File.write(script_path, script)
    system("node", script_path, chdir: Rails.root.to_s, exception: false)
    File.exist?(path)
  rescue => e
    false
  end

  def self.ask_claude_for_missing(screenshot_path, our_events_json)
    prompt = <<~PROMPT
      Tu es un vérificateur QA pour un agenda de danse. Regarde le screenshot dans #{screenshot_path}

      Voici les événements que nous avons DÉJÀ en base de données :
      #{our_events_json}

      Ta mission : identifier les événements VISIBLES sur le screenshot que nous N'AVONS PAS dans notre base.

      RÈGLE IMPORTANTE : la comparaison se fait par DATE (et HEURE si disponible), PAS par titre.
      Un event est "en base" s'il existe une entrée avec la MÊME DATE (et même heure si renseignée),
      peu importe que le titre soit différent. Les profs peuvent donner des noms différents au même event.

      Cherche sur le screenshot :
      - Des ateliers, stages, cours, vagues, jams avec des dates futures (après #{Date.current})
      - Des événements avec un lieu, un horaire, un prix

      Pour chaque event visible sur le screenshot, vérifie s'il existe une entrée dans notre base
      à la MÊME DATE. Si oui → il est couvert. Si non → il manque.

      Réponds UNIQUEMENT en JSON valide :
      {
        "missing_events": [
          {"titre": "...", "date": "YYYY-MM-DD si visible", "details": "ce que tu vois sur le screenshot"}
        ],
        "summary": "résumé en 1 phrase (ex: '2 events manquants détectés' ou 'aucun event manquant')"
      }

      IGNORE les events dont la date est PASSÉE (avant #{Date.current}).
      Si tu ne détectes aucun event manquant, retourne : {"missing_events": [], "summary": "Tous les events visibles sont en base"}
    PROMPT

    output, status = Open3.capture2e(
      CLAUDE_CLI_PATH, "-p", "--dangerously-skip-permissions",
      stdin_data: prompt
    )

    unless status.success?
      return { error: "Claude CLI failed: #{output.to_s.lines.first&.strip}" }
    end

    json_match = output.match(/\{.*\}/m)
    return { error: "No JSON in Claude response" } unless json_match

    parsed = JSON.parse(json_match[0], symbolize_names: true)
    { missing_events: parsed[:missing_events], summary: parsed[:summary] }
  rescue JSON::ParserError => e
    { error: "JSON parse error: #{e.message}" }
  rescue => e
    { error: "Claude error: #{e.message}" }
  end

  def self.generate_report(results)
    total_missing = results.sum { |r| r[:missing_events]&.size || 0 }
    errors = results.count { |r| r[:error].present? }
    clean = results.count { |r| r[:error].nil? && (r[:missing_events]&.empty? || r[:missing_events].nil?) }
    with_missing = results.count { |r| r[:missing_events]&.any? }
    total_duration = results.sum { |r| r[:duration_ms] || 0 }

    report = <<~MD
      # Scraping Missing Events Report

      **Date :** #{Date.current}
      **Durée totale :** #{(total_duration / 1000.0).round(1)}s

      ## Résumé

      | Métrique | Valeur |
      |----------|--------|
      | URLs vérifiées | #{results.size} |
      | ✅ Complet (rien ne manque) | #{clean} |
      | ⚠️ Events manquants détectés | #{with_missing} |
      | 💀 Erreurs | #{errors} |
      | **Total events manquants** | **#{total_missing}** |

      ## Détails

    MD

    results.each do |r|
      label = r[:nom].presence || r[:url].to_s.truncate(60)

      if r[:error]
        report += "### 💀 ##{r[:url_id]} #{label} (#{r[:duration_ms]}ms)\n\n"
        report += "**Erreur :** #{r[:error]}\n\n"
      elsif r[:missing_events]&.any?
        report += "### ⚠️ ##{r[:url_id]} #{label} (#{r[:duration_ms]}ms)\n\n"
        report += "**#{r[:missing_events].size} event(s) manquant(s) :**\n\n"
        r[:missing_events].each do |me|
          report += "- **#{me[:titre]}** (#{me[:date] || 'date ?'}) — #{me[:details]}\n"
        end
        report += "\n"
      else
        report += "### ✅ ##{r[:url_id]} #{label} (#{r[:duration_ms]}ms)\n\n"
        report += "#{r[:extra_info]}\n\n"
      end
    end

    File.write(REPORT_PATH, report)
    puts report
    REPORT_PATH
  end
end
