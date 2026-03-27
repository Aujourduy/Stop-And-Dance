require "test_helper"

class PagesAccessibilityTest < ActionDispatch::IntegrationTest
  setup do
    # Simulate modern browser for allow_browser check
    @headers = {
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }

    # Create test data
    @professor = Professor.create!(
      nom: "Test Professor",
      site_web: "https://example.com",
      bio: "Test bio"
    )

    @event = Event.create!(
      titre: "Test Event",
      date_debut: 2.days.from_now,
      date_fin: 2.days.from_now + 2.hours,
      lieu: "Paris",
      professor: @professor,
      type_event: :atelier
    )
  end

  # Public pages
  test "homepage is accessible" do
    get root_path, headers: @headers
    assert_response :success
    assert_select "h1"
  end

  test "about page is accessible" do
    get about_path, headers: @headers
    assert_response :success
  end

  test "contact page is accessible" do
    get contact_path, headers: @headers
    assert_response :success
  end

  test "proposants page is accessible" do
    get proposants_path, headers: @headers
    assert_response :success
  end

  test "actualites page is accessible" do
    get actualites_path, headers: @headers
    assert_response :success
  end

  # Events pages
  test "events index is accessible" do
    get evenements_path, headers: @headers
    assert_response :success
    assert_select "h1", text: /Liste des événements/
  end

  test "event show page is accessible" do
    get evenement_path(@event.slug), headers: @headers
    assert_response :success
  end

  test "events index with filters is accessible" do
    get evenements_path(gratuit: "true", atelier: "true"), headers: @headers
    assert_response :success
  end

  # Professor pages
  test "professor show page is accessible" do
    get professeur_path(@professor), headers: @headers
    assert_response :success
    assert_select "h1", text: @professor.nom
  end

  test "professor stats page is accessible" do
    get stats_professeur_path(@professor), headers: @headers
    assert_response :success
  end

  # SEO pages
  test "sitemap.xml is accessible" do
    get "/sitemap.xml", headers: @headers
    assert_response :success
    assert_equal "application/xml", @response.media_type
  end

  test "robots.txt is accessible" do
    get "/robots.txt", headers: @headers
    assert_response :success
  end

  # Newsletter
  test "newsletter signup works" do
    assert_difference("Newsletter.count", 1) do
      post newsletters_path, params: { newsletter: { email: "test@example.com" } }, headers: @headers
    end
    assert_redirected_to evenements_path
    follow_redirect!
    assert_response :success
  end

  # Admin pages (with HTTP Basic Auth)
  test "admin pages require authentication" do
    get admin_root_path, headers: @headers
    assert_response :unauthorized
  end

  test "admin pages are accessible with authentication" do
    # HTTP Basic Auth credentials from ENV or defaults
    username = ENV.fetch("ADMIN_USERNAME", "admin")
    password = ENV.fetch("ADMIN_PASSWORD", "changeme")
    auth_headers = @headers.merge({
      "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
    })
    get admin_root_path, headers: auth_headers
    assert_response :success
  end
end
