module SeoMetadata
  extend ActiveSupport::Concern

  included do
    before_action :set_default_meta_tags
  end

  private

  def set_default_meta_tags
    set_meta_tags(
      site: "Stop & Dance",
      title: "Stop & Dance - Agenda de danse exploratoire",
      description: "Agenda de référence des pratiques de danse exploratoires et non-performatives en France.",
      keywords: "danse, contact improvisation, 5 rythmes, authentic movement, ateliers danse, stages danse, danse exploratoire",
      canonical: request.original_url,
      og: {
        title: :title,
        type: "website",
        url: request.original_url,
        image: view_context.asset_path("og-default.jpg"),
        site_name: "Stop & Dance"
      },
      twitter: {
        card: "summary_large_image",
        site: "@stopanddance",
        title: :title,
        description: :description,
        image: view_context.asset_path("og-default.jpg")
      }
    )
  end

  def set_event_metadata(event)
    set_meta_tags(
      title: "#{event.titre} - #{l(event.date_debut, format: :long)}",
      description: event.description&.truncate(160) || "Atelier de danse avec #{event.professor.nom}",
      keywords: [ event.tags, "danse", event.lieu ].flatten.compact.join(", "),
      canonical: evenement_url(event.slug),
      og: {
        title: event.titre,
        type: "article",
        url: evenement_url(event.slug),
        image: event.photo_url || view_context.asset_path("og-default.jpg"),
        description: event.description&.truncate(200),
        site_name: "Stop & Dance"
      },
      twitter: {
        card: "summary_large_image",
        title: event.titre,
        description: event.description&.truncate(160),
        image: event.photo_url || view_context.asset_path("og-default.jpg")
      }
    )

    # Schema.org Event structured data (JSON-LD)
    set_meta_tags(
      structured_data: {
        '@context': "https://schema.org",
        '@type': "Event",
        name: event.titre,
        description: event.description,
        startDate: event.date_debut.iso8601,
        endDate: event.date_fin.iso8601,
        location: {
          '@type': "Place",
          name: event.lieu,
          address: event.adresse_complete
        },
        organizer: {
          '@type': "Person",
          name: event.professor.nom,
          url: event.professor.site_web
        },
        offers: {
          '@type': "Offer",
          price: event.gratuit ? 0 : event.prix_normal,
          priceCurrency: "EUR",
          availability: "https://schema.org/InStock",
          url: evenement_url(event.slug)
        },
        image: event.photo_url || view_context.asset_path("og-default.jpg")
      }
    )
  end

  def set_professor_metadata(professor)
    set_meta_tags(
      title: "#{professor.nom} - Stop & Dance",
      description: professor.bio&.truncate(160) || "Profil de #{professor.nom} - Ateliers de danse",
      canonical: professeur_url(professor),
      og: {
        title: professor.nom,
        description: professor.bio&.truncate(160),
        image: professor.avatar_url || view_context.asset_path("og-default.jpg"),
        url: professeur_url(professor),
        site_name: "Stop & Dance"
      },
      twitter: {
        card: "summary_large_image",
        title: professor.nom,
        description: professor.bio&.truncate(160),
        image: professor.avatar_url || view_context.asset_path("og-default.jpg")
      }
    )
  end

  def set_stats_metadata(professor)
    set_meta_tags(
      title: "Statistiques de #{professor.nom} - Stop & Dance",
      description: "Page de statistiques publiques pour #{professor.nom}",
      robots: "noindex, follow" # Don't index stats pages
    )
  end
end
