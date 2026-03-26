class Professor < ApplicationRecord
  # Associations
  has_many :professor_scraped_urls, dependent: :destroy
  has_many :scraped_urls, through: :professor_scraped_urls
  has_many :events, dependent: :destroy

  # Validations
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :site_web, format: { with: URI::DEFAULT_PARSER.make_regexp([ "http", "https" ]) }, allow_blank: true
end
