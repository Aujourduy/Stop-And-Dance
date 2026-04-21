require "playwright"

module Scrapers
  class PlaywrightScraper
    # User-Agent navigateur standard (Cloudflare bloque les UAs "bot" déclarés).
    # On s'identifie quand même via l'en-tête X-Bot-Operator pour transparence.
    BROWSER_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " \
                        "(KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"
    BOT_OPERATOR = "stopand.dance bot - contact@stopand.dance"

    def self.fetch(url, click_selector: nil, detail_link_selector: nil)
      Playwright.create(playwright_cli_executable_path: "./node_modules/.bin/playwright") do |playwright|
        playwright.chromium.launch(
          headless: true,
          args: [
            "--disable-blink-features=AutomationControlled",
            "--no-sandbox"
          ]
        ) do |browser|
          context = browser.new_context(
            userAgent: BROWSER_USER_AGENT,
            viewport: { width: 1920, height: 1080 },
            locale: "fr-FR",
            timezoneId: "Europe/Paris",
            extraHTTPHeaders: {
              "Accept-Language" => "fr-FR,fr;q=0.9,en;q=0.8",
              "X-Bot-Operator" => BOT_OPERATOR
            }
          )

          # Masquer les signaux d'automatisation trivialement détectables
          # (Cloudflare et autres regardent navigator.webdriver en priorité).
          context.add_init_script(
            script: <<~JS
              Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
              Object.defineProperty(navigator, 'languages', { get: () => ['fr-FR', 'fr', 'en'] });
              Object.defineProperty(navigator, 'plugins', { get: () => [1,2,3,4,5] });
            JS
          )

          page = context.new_page

          begin
            page.goto(url, waitUntil: "domcontentloaded", timeout: 120_000)

            # Attendre la résolution du challenge Cloudflare + rendu JS
            page.wait_for_timeout(8000)

            # Scroll pour lazy-loading
            page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            page.wait_for_timeout(2000)

            # Si un sélecteur "voir plus" est fourni, cliquer dessus pour
            # révéler le contenu masqué (ex. HelloAsso "Voir tous les événements").
            # Attend que le bouton apparaisse (jusqu'à 15s) avant de cliquer.
            if click_selector
              begin
                page.locator(click_selector).first.wait_for(state: "visible", timeout: 15_000)
              rescue StandardError
                # Bouton absent/pas visible → on continue sans click
              end

              3.times do
                break unless page.locator(click_selector).count > 0

                begin
                  btn = page.locator(click_selector).first
                  btn.scroll_into_view_if_needed(timeout: 3000)
                  btn.click(timeout: 5000)
                  page.wait_for_timeout(5000)
                  page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                  page.wait_for_timeout(2000)
                rescue StandardError
                  break
                end
              end
            end

            html = page.content

            # Enrichissement Phase 2 : visite des pages détail pour récupérer
            # des infos manquantes sur la page index (typiquement les horaires
            # sur HelloAsso qui n'apparaissent que sur la page détail).
            # Les sections détail sont injectées DANS le body avant </body>
            # pour que Nokogiri les conserve lors du cleaning.
            if detail_link_selector
              html = enrich_with_detail_pages(page, context, html, detail_link_selector)
            end

            {
              html: html,
              status: 200,
              content_type: "text/html",
              method: "playwright"
            }
          rescue Playwright::TimeoutError => e
            { error: "Playwright timeout: #{e.message}", status: nil }
          rescue StandardError => e
            { error: "Playwright error: #{e.message}", status: nil }
          ensure
            page.close rescue nil
            context.close rescue nil
          end
        end
      end
    rescue StandardError => e
      { error: "Playwright launch failed: #{e.message}", status: nil }
    end

    # Enrichit le HTML index en visitant chaque URL détail trouvée via
    # detail_link_selector. Pour chaque page détail, extrait le body text
    # et l'ajoute dans le HTML principal sous forme de <section> avec
    # data-detail-url. Le parseur Claude voit ainsi les infos détaillées
    # associées à chaque event (heure, tarif, adresse).
    def self.enrich_with_detail_pages(page, context, index_html, selector)
      detail_urls = page.eval_on_selector_all(selector, "els => [...new Set(els.map(e => e.href))]")
      return index_html if detail_urls.empty?

      # Limite de sécurité : max 20 pages détail par scrape.
      detail_urls = detail_urls.first(20)

      snippets = []
      detail_page = context.new_page
      begin
        detail_urls.each do |durl|
          begin
            detail_page.goto(durl, waitUntil: "domcontentloaded", timeout: 45_000)
            detail_page.wait_for_timeout(3000)
            body_text = detail_page.evaluate("document.body.innerText")
            # Garder les 3000 premiers chars (zone au-dessus de la billetterie
            # qui contient titre + date/heure + description + lieu).
            snippet = body_text.to_s.gsub("\r", "").squeeze("\n")[0, 3000]
            # Escape HTML pour éviter que des < > dans le texte cassent Nokogiri
            escaped = snippet.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
            snippets << %(<div data-detail-url="#{durl}">\n#{escaped}\n</div>)
          rescue StandardError
            # Page détail inaccessible : on continue sans bloquer l'index
          end
        end
      ensure
        detail_page.close rescue nil
      end

      return index_html if snippets.empty?

      # Injecter avant </body> pour que Nokogiri conserve les div dans le DOM
      injection = "<section id=\"detail-pages-enrichment\">\n#{snippets.join("\n")}\n</section>"
      if index_html =~ %r{</body>}i
        index_html.sub(%r{</body>}i, "#{injection}\n</body>")
      else
        index_html + injection
      end
    end
  end
end
