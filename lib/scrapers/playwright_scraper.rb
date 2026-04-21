require "playwright"

module Scrapers
  class PlaywrightScraper
    # User-Agent navigateur standard (Cloudflare bloque les UAs "bot" déclarés).
    # On s'identifie quand même via l'en-tête X-Bot-Operator pour transparence.
    BROWSER_USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 " \
                        "(KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"
    BOT_OPERATOR = "stopand.dance bot - contact@stopand.dance"

    def self.fetch(url, click_selector: nil)
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
            # On clique en boucle tant que le bouton est présent, pour révéler
            # plusieurs pages si besoin.
            if click_selector
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
  end
end
