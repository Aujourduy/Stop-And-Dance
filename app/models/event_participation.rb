class EventParticipation < ApplicationRecord
  belongs_to :event
  belongs_to :professor

  validates :professor_id, uniqueness: { scope: :event_id }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
