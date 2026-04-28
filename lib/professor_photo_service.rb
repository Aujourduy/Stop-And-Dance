require "open-uri"
require "cloudinary"

# Upload des photos de Professor sur Cloudinary.
#
# Architecture identique à ScrapedUrlAvatarService :
# - process_upload : upload depuis form admin (Cropper.js produit déjà
#   un blob carré 300×300, on upload tel quel)
# - download_from_url : télécharge depuis une URL externe (typiquement
#   trouvée par le scraping) puis upload sur Cloudinary
class ProfessorPhotoService
  SIZE = 300

  # Folder Cloudinary segmenté par environnement Rails (dev/prod/test).
  def self.folder
    "stop-and-dance-#{Rails.env}/professors"
  end

  def self.process_upload(professor, uploaded_file)
    return { error: "No file" } if uploaded_file.blank?

    public_id = "prof_#{professor.id}"

    result = Cloudinary::Uploader.upload(
      uploaded_file,
      folder: folder,
      public_id: public_id,
      overwrite: true,
      invalidate: true,
      resource_type: "image",
      transformation: [
        { width: SIZE, height: SIZE, crop: "fill", gravity: "auto" },
        { quality: "auto", fetch_format: "auto" }
      ]
    )

    result["secure_url"]
  rescue => e
    Rails.logger.error("ProfessorPhotoService upload error for ##{professor.id}: #{e.message}")
    { error: e.message }
  end

  def self.download_from_url(professor, url)
    return { error: "No URL" } if url.blank?
    return { error: "Already a Cloudinary URL" } if url.include?("res.cloudinary.com")

    public_id = "prof_#{professor.id}"

    result = Cloudinary::Uploader.upload(
      url,
      folder: folder,
      public_id: public_id,
      overwrite: true,
      invalidate: true,
      resource_type: "image",
      transformation: [
        { width: SIZE, height: SIZE, crop: "fill", gravity: "auto" },
        { quality: "auto", fetch_format: "auto" }
      ]
    )

    result["secure_url"]
  rescue => e
    Rails.logger.error("ProfessorPhotoService download error for ##{professor.id}: #{e.message}")
    { error: e.message }
  end

  def self.delete_photos(professor)
    public_id = "#{folder}/prof_#{professor.id}"
    Cloudinary::Uploader.destroy(public_id, resource_type: "image")
  rescue => e
    Rails.logger.warn("Cloudinary destroy failed for #{public_id}: #{e.message}")
  end
end
