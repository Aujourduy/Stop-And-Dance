namespace :cloudinary do
  desc "Migre tous les avatars (ScrapedUrl + Professor) vers Cloudinary"
  task migrate: :environment do
    puts "=== Migration ScrapedUrl avatars ==="
    migrate_scraped_url_avatars

    puts ""
    puts "=== Migration Professor photos ==="
    migrate_professor_photos

    puts ""
    puts "=== Migration terminée ==="
  end

  def migrate_scraped_url_avatars
    require "scraped_url_avatar_service"

    scraped_urls = ScrapedUrl.where.not(avatar_url: [ nil, "" ])
                             .where("avatar_url NOT LIKE ?", "%cloudinary.com%")

    puts "#{scraped_urls.count} avatars à migrer"
    migrated = 0
    failed = 0

    scraped_urls.find_each do |s|
      old_url = s.avatar_url

      # Si chemin local /avatars/X.png, on prend le fichier disque
      # Si URL externe http(s)://, on laisse Cloudinary la fetcher
      source = if old_url.start_with?("/avatars/")
        local_path = Rails.root.join("public", old_url.sub("?v=", "?v=").split("?").first.sub(%r{^/}, ""))
        File.exist?(local_path) ? local_path.to_s : nil
      elsif old_url.start_with?("/photos/")
        local_path = Rails.root.join("public", old_url.sub("?v=", "?v=").split("?").first.sub(%r{^/}, ""))
        File.exist?(local_path) ? local_path.to_s : nil
      elsif old_url.start_with?("http")
        old_url
      else
        nil
      end

      if source.nil?
        puts "  ##{s.id} #{old_url[0..50]} → SKIP (source introuvable)"
        failed += 1
        next
      end

      # Upload via Cloudinary directement (sans repasser par le service
      # pour éviter le re-crop d'images déjà 300×300)
      result = Cloudinary::Uploader.upload(
        source,
        folder: ScrapedUrlAvatarService.folder,
        public_id: "scraped_url_#{s.id}",
        overwrite: true,
        invalidate: true,
        resource_type: "image",
        transformation: [
          { width: ScrapedUrlAvatarService::SIZE, height: ScrapedUrlAvatarService::SIZE, crop: "fill", gravity: "auto" },
          { quality: "auto", fetch_format: "auto" }
        ]
      )

      s.update_column(:avatar_url, result["secure_url"])
      puts "  ##{s.id} → #{result['secure_url'][0..70]}..."
      migrated += 1
    rescue => e
      puts "  ##{s.id} #{old_url[0..50]} → ERR: #{e.message[0..80]}"
      failed += 1
    end

    puts ""
    puts "ScrapedUrl : #{migrated} migrées, #{failed} échouées"
  end

  def migrate_professor_photos
    require "professor_photo_service"

    professors = Professor.where.not(avatar_url: [ nil, "" ])
                          .where("avatar_url NOT LIKE ?", "%cloudinary.com%")

    puts "#{professors.count} photos à migrer"
    migrated = 0
    failed = 0

    professors.find_each do |p|
      old_url = p.avatar_url

      source = if old_url.start_with?("/photos/") || old_url.start_with?("/avatars/")
        local_path = Rails.root.join("public", old_url.split("?").first.sub(%r{^/}, ""))
        File.exist?(local_path) ? local_path.to_s : nil
      elsif old_url.start_with?("http")
        old_url
      else
        nil
      end

      if source.nil?
        puts "  ##{p.id} #{old_url[0..50]} → SKIP (source introuvable)"
        failed += 1
        next
      end

      result = Cloudinary::Uploader.upload(
        source,
        folder: ProfessorPhotoService.folder,
        public_id: "prof_#{p.id}",
        overwrite: true,
        invalidate: true,
        resource_type: "image",
        transformation: [
          { width: ProfessorPhotoService::SIZE, height: ProfessorPhotoService::SIZE, crop: "fill", gravity: "auto" },
          { quality: "auto", fetch_format: "auto" }
        ]
      )

      p.update_column(:avatar_url, result["secure_url"])
      puts "  ##{p.id} #{p.nom} → #{result['secure_url'][0..70]}..."
      migrated += 1
    rescue => e
      puts "  ##{p.id} #{old_url[0..50]} → ERR: #{e.message[0..80]}"
      failed += 1
    end

    puts ""
    puts "Professor : #{migrated} migrées, #{failed} échouées"
  end
end
