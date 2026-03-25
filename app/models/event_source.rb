class EventSource < ApplicationRecord
  # Associations
  belongs_to :event
  belongs_to :scraped_url
end
