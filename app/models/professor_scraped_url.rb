class ProfessorScrapedUrl < ApplicationRecord
  # Associations
  belongs_to :professor
  belongs_to :scraped_url
end
