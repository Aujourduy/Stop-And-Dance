require "open-uri"
require "cloudinary"

# Upload des avatars de ScrapedUrl sur Cloudinary.
#
# Architecture :
# - Cropper.js (côté navigateur) produit un blob carré 300×300 PNG ;
#   on l'upload tel quel sur Cloudinary, sans retraitement.
# - Pour les URLs externes (saisie manuelle / scraping logo distant),
#   on délègue le crop carré + pad couleur dominante à Cloudinary
#   via les transformations URL.
#
# Avantages vs stockage local :
# - Persistance : indépendant du container Docker (rebuilds OK)
# - CDN : images servies par Cloudinary, plus rapide
# - WebP/AVIF auto via f_auto si on l'active dans la transformation URL
class ScrapedUrlAvatarService
  SIZE = 300
  FOLDER = "stopanddance/avatars".freeze

  # Upload direct depuis le form admin. Le blob arrive déjà cropé carré
  # par Cropper.js v2 côté navigateur — on l'upload tel quel.
  # Retourne l'URL Cloudinary HTTPS (stockée dans avatar_url),
  # ou { error: "..." } en cas d'échec.
  def self.process_upload(scraped_url, uploaded_file)
    return { error: "No file" } if uploaded_file.blank?

    public_id = "scraped_url_#{scraped_url.id}"

    result = Cloudinary::Uploader.upload(
      uploaded_file,
      folder: FOLDER,
      public_id: public_id,
      overwrite: true,
      invalidate: true,                  # purge cache CDN si update
      resource_type: "image",
      transformation: [
        { width: SIZE, height: SIZE, crop: "fill", gravity: "center" },
        { quality: "auto", fetch_format: "auto" }
      ]
    )

    result["secure_url"]
  rescue => e
    Rails.logger.error("ScrapedUrlAvatarService upload error for ##{scraped_url.id}: #{e.message}")
    { error: e.message }
  end

  # Télécharge une image depuis une URL externe et l'upload sur Cloudinary
  # avec crop+pad couleur auto. Utilisé quand on saisit une URL dans le
  # form (vs upload de fichier).
  def self.download_and_square(scraped_url, url)
    return { error: "No URL" } if url.blank?
    return { error: "Already a Cloudinary URL" } if url.include?("res.cloudinary.com")
    return { error: "Skip local path (not a URL)" } if url.start_with?("/")

    public_id = "scraped_url_#{scraped_url.id}"

    # Cloudinary peut télécharger directement depuis une URL distante.
    # On laisse Cloudinary gérer le crop + pad couleur dominante via
    # c_pad + b_auto:border (auto-détection couleur des bords).
    result = Cloudinary::Uploader.upload(
      url,
      folder: FOLDER,
      public_id: public_id,
      overwrite: true,
      invalidate: true,
      resource_type: "image",
      transformation: [
        { width: SIZE, height: SIZE, crop: "pad", background: "auto:border" },
        { quality: "auto", fetch_format: "auto" }
      ]
    )

    result["secure_url"]
  rescue => e
    Rails.logger.error("ScrapedUrlAvatarService download error for ##{scraped_url.id}: #{e.message}")
    { error: e.message }
  end

  def self.delete_avatar(scraped_url)
    public_id = "#{FOLDER}/scraped_url_#{scraped_url.id}"
    Cloudinary::Uploader.destroy(public_id, resource_type: "image")
  rescue => e
    Rails.logger.warn("Cloudinary destroy failed for #{public_id}: #{e.message}")
  end
end
