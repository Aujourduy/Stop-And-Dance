require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @prof1 = Professor.create!(nom: "Laraki", prenom: "Bouchra", status: "auto")
    @prof2 = Professor.create!(nom: "Doucet", prenom: "Jeremy", status: "auto")
    @prof3 = Professor.create!(nom: "Rouxel", prenom: "Kevin", status: "auto")
  end

  test "un event doit avoir au moins un prof (validation)" do
    e = Event.new(titre: "Sans prof", date_debut_date: Date.current + 5, date_fin_date: Date.current + 5)
    assert_not e.valid?
    assert_includes e.errors[:base].join, "au moins un professeur"
  end

  test "event solo : professor_id auto-synced sur prof0" do
    e = solo_event(@prof1)
    assert_equal @prof1.id, e.professor_id
    assert_equal [ @prof1 ], e.professors.to_a
    assert_equal 1, e.event_participations.count
    assert_not e.coanimation?
  end

  test "event duo : ordre respecté et primary_professor = prof0" do
    e = duo_event(@prof1, @prof2)
    assert_equal [ @prof1.id, @prof2.id ], e.professors.map(&:id)
    assert_equal @prof1.id, e.primary_professor.id
    assert_equal [ @prof2 ], e.coanimators
    assert e.coanimation?
  end

  test "display_professors formatte avec × pour coanimation" do
    e = duo_event(@prof1, @prof2)
    assert_equal "Bouchra Laraki × Jeremy Doucet", e.display_professors
  end

  test "display_professors solo" do
    e = solo_event(@prof1)
    assert_equal "Bouchra Laraki", e.display_professors
  end

  test "professor_id reste en phase si on retire prof0" do
    e = duo_event(@prof1, @prof2)
    assert_equal @prof1.id, e.professor_id

    # Supprimer le 1er prof → 2e devient principal au prochain save
    e.event_participations.where(professor: @prof1).destroy_all
    e.reload
    # Sync manuel déclenché par update
    e.update!(description: "touch")
    assert_equal @prof2.id, e.professor_id
  end

  test "Professor#events retourne events via participations" do
    solo_event(@prof1)
    duo_event(@prof1, @prof2)
    duo_event(@prof3, @prof2)

    assert_equal 2, @prof1.events.count
    assert_equal 2, @prof2.events.count
    assert_equal 1, @prof3.events.count
  end

  test "duplicata paire (event, prof) rejeté" do
    e = solo_event(@prof1)
    dup = EventParticipation.new(event: e, professor: @prof1, position: 2)
    assert_not dup.valid?
  end

  private

  def solo_event(prof)
    e = Event.new(titre: "Atelier #{prof.nom}", date_debut_date: Date.current + 5, date_fin_date: Date.current + 5)
    e.event_participations.build(professor: prof, position: 0)
    e.save!
    e
  end

  def duo_event(p1, p2)
    e = Event.new(titre: "Duo #{p1.nom}×#{p2.nom}", date_debut_date: Date.current + 10, date_fin_date: Date.current + 10)
    e.event_participations.build(professor: p1, position: 0)
    e.event_participations.build(professor: p2, position: 1)
    e.save!
    e
  end
end
