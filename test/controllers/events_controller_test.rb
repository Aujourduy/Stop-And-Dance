require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @professor = Professor.create!(
      nom: "Test Professor",
      site_web: "https://example.com"
    )

    @event = Event.create!(
      titre: "Test Event",
      date_debut: 2.days.from_now,
      date_fin: 2.days.from_now + 2.hours,
      lieu: "Paris",
      adresse_complete: "123 Test St, Paris",
      professor: @professor,
      type_event: :atelier,
      gratuit: false,
      prix_normal: 25.0
    )
  end

  test "should get index" do
    get evenements_url
    assert_response :success
  end

  test "should get show" do
    get evenement_url(@event.slug)
    assert_response :success
  end

  test "index should only show future events" do
    past_event = Event.create!(
      titre: "Past Event",
      date_debut: 2.days.ago,
      date_fin: 2.days.ago + 2.hours,
      lieu: "Paris",
      professor: @professor,
      type_event: :atelier
    )

    get evenements_url
    assert_response :success
    assert_select "h3", text: @event.titre
    assert_select "h3", text: past_event.titre, count: 0
  end

  test "show should increment professor consultations count" do
    initial_count = @professor.consultations_count || 0

    get evenement_url(@event.slug)

    @professor.reload
    assert_equal initial_count + 1, @professor.consultations_count
  end

  test "show should redirect if event not found" do
    get evenement_url("invalid-slug")
    assert_redirected_to evenements_path
  end

  test "should filter by type_event atelier" do
    stage = Event.create!(
      titre: "Stage Event",
      date_debut: 3.days.from_now,
      date_fin: 3.days.from_now + 2.hours,
      lieu: "Lyon",
      professor: @professor,
      type_event: :stage
    )

    get evenements_url, params: { atelier: "true" }
    assert_response :success
    assert_select "h3", text: @event.titre
    assert_select "h3", text: stage.titre, count: 0
  end

  test "should filter by type_event stage" do
    stage = Event.create!(
      titre: "Stage Event",
      date_debut: 3.days.from_now,
      date_fin: 3.days.from_now + 2.hours,
      lieu: "Lyon",
      professor: @professor,
      type_event: :stage
    )

    get evenements_url, params: { stage: "true" }
    assert_response :success
    assert_select "h3", text: stage.titre
    assert_select "h3", text: @event.titre, count: 0
  end

  test "should filter by gratuit" do
    gratuit_event = Event.create!(
      titre: "Free Event",
      date_debut: 3.days.from_now,
      date_fin: 3.days.from_now + 2.hours,
      lieu: "Lyon",
      professor: @professor,
      type_event: :atelier,
      gratuit: true
    )

    get evenements_url, params: { gratuit: "true" }
    assert_response :success
    assert_select "h3", text: gratuit_event.titre
    assert_select "h3", text: @event.titre, count: 0
  end

  test "should filter by lieu" do
    lyon_event = Event.create!(
      titre: "Lyon Event",
      date_debut: 3.days.from_now,
      date_fin: 3.days.from_now + 2.hours,
      lieu: "Lyon",
      professor: @professor,
      type_event: :atelier
    )

    get evenements_url, params: { lieu: "Lyon" }
    assert_response :success
    assert_select "h3", text: lyon_event.titre
    assert_select "h3", text: @event.titre, count: 0
  end

  test "should filter by date_debut" do
    future_event = Event.create!(
      titre: "Far Future Event",
      date_debut: 10.days.from_now,
      date_fin: 10.days.from_now + 2.hours,
      lieu: "Paris",
      professor: @professor,
      type_event: :atelier
    )

    get evenements_url, params: { date_debut: 5.days.from_now.to_date.to_s }
    assert_response :success
    assert_select "h3", text: future_event.titre
    assert_select "h3", text: @event.titre, count: 0
  end

  test "should filter by en_ligne" do
    @event.update!(en_ligne: false)
    online_event = Event.create!(
      titre: "Online Event",
      date_debut: 3.days.from_now,
      date_fin: 3.days.from_now + 2.hours,
      lieu: "En ligne",
      professor: @professor,
      type_event: :atelier,
      en_ligne: true
    )

    get evenements_url, params: { en_ligne: "true" }
    assert_response :success
    assert_select "h3", text: online_event.titre
    assert_select "h3", text: @event.titre, count: 0
  end

  test "should filter by en_presentiel" do
    @event.update!(en_ligne: false)
    online_event = Event.create!(
      titre: "Online Event",
      date_debut: 3.days.from_now,
      date_fin: 3.days.from_now + 2.hours,
      lieu: "En ligne",
      professor: @professor,
      type_event: :atelier,
      en_ligne: true
    )

    get evenements_url, params: { en_presentiel: "true" }
    assert_response :success
    assert_select "h3", text: @event.titre
    assert_select "h3", text: online_event.titre, count: 0
  end

  test "should combine multiple filters" do
    lyon_stage = Event.create!(
      titre: "Lyon Stage",
      date_debut: 3.days.from_now,
      date_fin: 3.days.from_now + 2.hours,
      lieu: "Lyon",
      professor: @professor,
      type_event: :stage,
      gratuit: true
    )

    get evenements_url, params: { lieu: "Lyon", stage: "true", gratuit: "true" }
    assert_response :success
    assert_select "h3", text: lyon_stage.titre
    assert_select "h3", text: @event.titre, count: 0
  end
end
