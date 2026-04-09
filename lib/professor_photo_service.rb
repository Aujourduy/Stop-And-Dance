require "mini_magick"

class ProfessorPhotoService
  PHOTO_DIR = Rails.root.join("public", "photos", "professors")
  SIZES = { large: 300, medium: 150, thumb: 80 }.freeze

  def self.process_upload(professor, uploaded_file)
    return { error: "No file" } if uploaded_file.blank?

    # Ensure directory exists
    FileUtils.mkdir_p(PHOTO_DIR)

    # Generate filename from professor ID
    basename = "prof_#{professor.id}"

    # Process and save each size
    SIZES.each do |name, size|
      output_path = PHOTO_DIR.join("#{basename}_#{name}.jpg")

      image = MiniMagick::Image.read(uploaded_file.read)
      uploaded_file.rewind

      image.combine_options do |c|
        c.resize "#{size}x#{size}^"
        c.gravity "center"
        c.extent "#{size}x#{size}"
        c.quality 85
      end
      image.format "jpg"
      image.write(output_path)
    end

    # Return URL for the large version
    "/photos/professors/#{basename}_large.jpg"
  rescue => e
    { error: e.message }
  end

  def self.delete_photos(professor)
    basename = "prof_#{professor.id}"
    SIZES.each_key do |name|
      path = PHOTO_DIR.join("#{basename}_#{name}.jpg")
      FileUtils.rm_f(path)
    end
  end

  def self.download_from_url(professor, url)
    return { error: "No URL" } if url.blank?

    require "open-uri"
    tempfile = URI.parse(url).open
    uploaded = ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: "download.jpg",
      type: "image/jpeg"
    )
    process_upload(professor, uploaded)
  rescue => e
    { error: e.message }
  end
end
