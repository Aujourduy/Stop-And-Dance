require "cloudinary"

# Configuration Cloudinary depuis variables d'environnement.
# Variables requises (dans .env.production / .env) :
#   CLOUDINARY_CLOUD_NAME
#   CLOUDINARY_API_KEY
#   CLOUDINARY_API_SECRET
#   CLOUDINARY_UPLOAD_PRESET (optionnel, pour uploads non-signés)
#
# Utilisation :
#   Cloudinary::Uploader.upload(file, public_id: "avatars/scraped_url_42",
#                                     overwrite: true,
#                                     resource_type: "image")
Cloudinary.config do |config|
  config.cloud_name        = ENV["CLOUDINARY_CLOUD_NAME"]
  config.api_key           = ENV["CLOUDINARY_API_KEY"]
  config.api_secret        = ENV["CLOUDINARY_API_SECRET"]
  config.secure            = true
  config.cdn_subdomain     = false
end
