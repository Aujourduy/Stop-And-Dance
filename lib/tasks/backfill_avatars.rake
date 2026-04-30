require "open-uri"
require "nokogiri"

# Récupère og:image (ou twitter:image en fallback) des sites profs sans avatar,
# et upload sur Cloudinary via ScrapedUrlAvatarService + ProfessorPhotoService.
namespace :avatars do
  desc "Backfill avatars manquants pour profs avec events futurs visibles"
  task backfill: :environment do
    events = Event.visible.where("date_debut_date >= ?", Date.current).to_a
    no_avatar = events.select { |e| e.card_image_url.blank? }
    by_prof = no_avatar.group_by { |e| e.primary_professor&.id }.compact

    puts "Profs sans avatar: #{by_prof.size}"
    puts ""

    by_prof.each do |prof_id, evs|
      prof = evs.first.primary_professor
      scraped_url = evs.first.scraped_url
      next unless prof && scraped_url&.url.present?

      puts "→ Prof ##{prof.id} #{prof.prenom} #{prof.nom} (#{evs.size} events) | source: #{scraped_url.url}"

      img_url = fetch_og_image(scraped_url.url)
      if img_url.blank?
        puts "  ❌ Pas d'og:image trouvée"
        next
      end
      puts "  → og:image: #{img_url}"

      # Upload sur Cloudinary via les 2 services (prof + scraped_url)
      prof_result = ProfessorPhotoService.download_from_url(prof, img_url)
      if prof_result.is_a?(String)
        prof.update!(avatar_url: prof_result)
        puts "  ✅ Prof avatar: #{prof_result[0..80]}"
      else
        puts "  ❌ Prof upload error: #{prof_result.inspect}"
      end

      su_result = ScrapedUrlAvatarService.download_and_square(scraped_url, img_url)
      if su_result.is_a?(String)
        scraped_url.update!(avatar_url: su_result)
        puts "  ✅ ScrapedUrl avatar: #{su_result[0..80]}"
      else
        puts "  ❌ ScrapedUrl upload error: #{su_result.inspect}"
      end

      puts ""
    end
  end

  def fetch_og_image(url)
    html = URI.open(url, "User-Agent" => "Mozilla/5.0 (Stop&Dance bot)", read_timeout: 15).read
    doc = Nokogiri::HTML(html)
    og = doc.at('meta[property="og:image"]')&.[]("content")
    return og if og.present?
    twitter = doc.at('meta[name="twitter:image"]')&.[]("content")
    twitter.presence
  rescue => e
    Rails.logger.warn("fetch_og_image error for #{url}: #{e.message}")
    nil
  end
end
