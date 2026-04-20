require "mini_magick"
require "open-uri"
require "shellwords"

# Télécharge un avatar de ScrapedUrl depuis une URL et produit une version
# carrée (SIZE×SIZE). Si l'image source est déjà quasi-carrée (ratio
# dans SQUARE_TOLERANCE), elle est simplement redimensionnée. Si elle
# est rectangulaire (logo collectif 500×100 par ex.), elle est paddée
# avec la couleur dominante détectée pour obtenir un carré propre.
class ScrapedUrlAvatarService
  AVATAR_DIR = Rails.root.join("public", "avatars")
  SIZE = 300
  SQUARE_TOLERANCE = 0.10 # ratio considéré "carré" : 0.9 < h/w < 1.1

  def self.download_and_square(scraped_url, url)
    return { error: "No URL" } if url.blank?
    return { error: "Already a local avatar" } if url.start_with?("/avatars/")
    return { error: "Skip local path (not a URL)" } if url.start_with?("/")

    FileUtils.mkdir_p(AVATAR_DIR)

    # Télécharger l'image en tempfile
    tempfile = URI.parse(url).open(read_timeout: 20)
    source = MiniMagick::Image.read(tempfile.read)
    tempfile.rewind rescue nil

    filename = "scraped_url_#{scraped_url.id}.png"
    output_path = AVATAR_DIR.join(filename)

    width = source.width.to_f
    height = source.height.to_f
    ratio = height / width

    if (1 - SQUARE_TOLERANCE..1 + SQUARE_TOLERANCE).cover?(ratio)
      # Déjà carré → simple resize avec cover
      source.combine_options do |c|
        c.resize "#{SIZE}x#{SIZE}^"
        c.gravity "center"
        c.extent "#{SIZE}x#{SIZE}"
      end
      source.format "png"
      source.write(output_path)
    else
      # Rectangulaire → détecter couleur dominante et padder
      bg_color = dominant_color(source)
      square_with_padding(source, bg_color, output_path)
    end

    "/avatars/#{filename}"
  rescue => e
    Rails.logger.error("ScrapedUrlAvatarService error for ##{scraped_url.id}: #{e.message}")
    { error: e.message }
  end

  # Détecte la couleur dominante via ImageMagick : flatten sur blanc (pour
  # écraser transparence), reduce à 1 pixel, extrait la couleur hex.
  def self.dominant_color(image)
    hex = `convert #{Shellwords.escape(image.path)} -background white -alpha remove -resize 1x1 -format "%[hex:u.p{0,0}]" info: 2>/dev/null`.strip
    return "#ffffff" if hex.empty?
    "##{hex[0, 6]}"
  rescue
    "#ffffff"
  end

  # Produit un carré SIZE×SIZE : resize le logo pour qu'il tienne dans le
  # carré en gardant son ratio, puis pad avec bg_color pour atteindre SIZE.
  def self.square_with_padding(source, bg_color, output_path)
    system(
      "convert",
      source.path,
      "-background", bg_color,
      "-gravity", "center",
      "-resize", "#{SIZE}x#{SIZE}",
      "-extent", "#{SIZE}x#{SIZE}",
      "-alpha", "remove",
      output_path.to_s
    ) or raise "convert failed"
  end

  def self.delete_avatar(scraped_url)
    path = AVATAR_DIR.join("scraped_url_#{scraped_url.id}.png")
    FileUtils.rm_f(path)
  end
end
