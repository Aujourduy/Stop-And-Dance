require "test_helper"

class EventParticipationTest < ActiveSupport::TestCase
  setup do
    @prof1 = Professor.create!(nom: "Dupont", prenom: "Marie", status: "auto")
    @prof2 = Professor.create!(nom: "Martin", prenom: "Jean", status: "auto")
    @event = build_event_with(@prof1)
  end

  test "unicité de la paire (event, professor)" do
    assert_raises(ActiveRecord::RecordInvalid) do
      EventParticipation.create!(event: @event, professor: @prof1, position: 5)
    end
  end

  test "position >= 0" do
    part = EventParticipation.new(event: @event, professor: @prof2, position: -1)
    assert_not part.valid?
    assert_includes part.errors[:position].join, "supérieur"
  end

  test "ordered scope trie par position puis id" do
    EventParticipation.create!(event: @event, professor: @prof2, position: 1)
    prof3 = Professor.create!(nom: "Durand", status: "auto")
    EventParticipation.create!(event: @event, professor: prof3, position: 2)

    profs_ordered = @event.event_participations.reload.map(&:professor_id)
    assert_equal [ @prof1.id, @prof2.id, prof3.id ], profs_ordered
  end

  test "destroy event cascade delete participations" do
    EventParticipation.create!(event: @event, professor: @prof2, position: 1)
    count = @event.event_participations.count
    assert_equal 2, count

    @event.destroy
    assert_equal 0, EventParticipation.where(event_id: @event.id).count
  end

  private

  def build_event_with(prof)
    e = Event.new(
      titre: "Atelier test",
      date_debut_date: Date.current + 10,
      date_fin_date: Date.current + 10
    )
    e.event_participations.build(professor: prof, position: 0)
    e.save!
    e
  end
end
