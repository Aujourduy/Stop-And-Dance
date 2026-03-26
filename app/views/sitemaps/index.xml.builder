xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Static pages
  @static_pages.each do |page|
    xml.url do
      xml.loc page[:loc]
      xml.lastmod Time.current.iso8601
      xml.changefreq 'weekly'
      xml.priority page[:priority]
    end
  end

  # Events
  @events.each do |event|
    xml.url do
      xml.loc evenement_url(event.slug)
      xml.lastmod event.updated_at.iso8601
      xml.changefreq 'weekly'
      xml.priority 0.9
    end
  end

  # Professor profiles
  Professor.find_each do |professor|
    xml.url do
      xml.loc professeur_url(professor)
      xml.lastmod professor.updated_at.iso8601
      xml.changefreq 'monthly'
      xml.priority 0.7
    end
  end
end
