require "application_system_test_case"

class EventsTest < ApplicationSystemTestCase
  setup do
    # Create test data
    @professor = Professor.create!(
      nom: "Sophie Marchand",
      email: "sophie@example.com",
      site_web: "https://example.com",
      bio: "Danseuse Contact Impro"
    )

    # Future events (will be visible)
    @event_paid = Event.create!(
      titre: "Atelier Contact Improvisation",
      description: "Un atelier payant",
      date_debut: 2.days.from_now,
      date_fin: 2.days.from_now + 2.hours,
      lieu: "Paris",
      type_event: :atelier,
      prix_normal: 20,
      gratuit: false,
      professor: @professor
    )

    @event_free = Event.create!(
      titre: "Jam Gratuite",
      description: "Jam ouverte à tous",
      date_debut: 5.days.from_now,
      date_fin: 5.days.from_now + 3.hours,
      lieu: "Lyon",
      type_event: :atelier,
      prix_normal: 0,
      gratuit: true,
      professor: @professor
    )

    # Create more events for infinite scroll test
    10.times do |i|
      Event.create!(
        titre: "Event #{i + 1}",
        description: "Description event #{i + 1}",
        date_debut: (10 + i).days.from_now,
        date_fin: (10 + i).days.from_now + 2.hours,
        lieu: "Paris",
        type_event: :atelier,
        gratuit: false,
        prix_normal: 15,
        professor: @professor
      )
    end
  end

  test "homepage loads successfully" do
    visit root_path

    assert_selector "h1", text: /Stop|Dance/i
    assert_selector "nav"
  end

  test "events list displays events" do
    visit evenements_path

    assert_selector "h1", text: /Agenda/
    assert_text @event_paid.titre
    assert_text @event_free.titre
  end

  test "filter by gratuit checkbox exists" do
    visit evenements_path

    # Both events should be visible initially
    assert_text @event_paid.titre
    assert_text @event_free.titre

    # Filter sidebar should contain filter options
    assert_text "Gratuit"
  end

  test "filter by date input exists" do
    visit evenements_path

    # Date filter input should exist
    assert_selector "input[name=date_debut]", visible: :all
  end

  test "newsletter form exists" do
    visit evenements_path

    # Newsletter signup form should be present in page
    assert_text "S'inscrire à la newsletter"
    assert_selector "input[name*=email]"
  end

  test "events page displays events" do
    visit evenements_path

    # Should display the created events
    assert_text "Atelier Contact Improvisation"
    assert_text "Jam Gratuite"
  end
end
