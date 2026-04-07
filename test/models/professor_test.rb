require "test_helper"

class ProfessorTest < ActiveSupport::TestCase
  # Normalisation tests
  test "normaliser_nom downcases" do
    assert_equal "marie dupont", Professor.normaliser_nom("Marie Dupont")
    assert_equal "marie dupont", Professor.normaliser_nom("MARIE DUPONT")
  end

  test "normaliser_nom strips accents" do
    assert_equal "stephane", Professor.normaliser_nom("Stéphane")
    assert_equal "jose-maria garcia", Professor.normaliser_nom("José-María García")
    assert_equal "francois", Professor.normaliser_nom("François")
    assert_equal "noel", Professor.normaliser_nom("Noël")
  end

  test "normaliser_nom squeezes multiple spaces" do
    assert_equal "marie dupont", Professor.normaliser_nom("  marie  dupont  ")
    assert_equal "marie dupont", Professor.normaliser_nom("marie   dupont")
  end

  test "normaliser_nom strips leading and trailing spaces" do
    assert_equal "marie dupont", Professor.normaliser_nom("  marie dupont  ")
    assert_equal "jean", Professor.normaliser_nom(" jean ")
  end

  test "normaliser_nom handles nil and empty strings" do
    assert_nil Professor.normaliser_nom(nil)
    assert_nil Professor.normaliser_nom("")
    assert_nil Professor.normaliser_nom("   ")
  end

  test "normaliser_nom handles special characters" do
    assert_equal "jean-luc", Professor.normaliser_nom("Jean-Luc")
    assert_equal "marie d'arc", Professor.normaliser_nom("Marie d'Arc")
  end

  # find_or_create_from_scrape tests
  test "find_or_create_from_scrape returns existing professor by normalized name" do
    existing = Professor.create!(nom: "Marie Dupont", email: "marie@example.com")

    # Même nom avec casse différente
    found = Professor.find_or_create_from_scrape(nom: "marie dupont")
    assert_equal existing.id, found.id
    assert_equal "Marie Dupont", existing.nom # Nom original préservé
  end

  test "find_or_create_from_scrape returns existing professor with accents" do
    existing = Professor.create!(nom: "Stéphane Lefèvre")

    # Même nom sans accents
    found = Professor.find_or_create_from_scrape(nom: "Stephane Lefevre")
    assert_equal existing.id, found.id
  end

  test "find_or_create_from_scrape creates new professor if not exists" do
    assert_difference "Professor.count", 1 do
      Professor.find_or_create_from_scrape(nom: "Jean Nouveau", email: "jean@example.com")
    end
  end

  test "find_or_create_from_scrape sets status to auto" do
    prof = Professor.find_or_create_from_scrape(nom: "Auto Prof")
    assert_equal "auto", prof.status
  end

  test "find_or_create_from_scrape accepts additional attributes" do
    prof = Professor.find_or_create_from_scrape(
      nom: "Marie Test",
      email: "marie@test.com",
      bio: "Bio test",
      site_web: "https://example.com"
    )

    assert_equal "marie@test.com", prof.email
    assert_equal "Bio test", prof.bio
    assert_equal "https://example.com", prof.site_web
  end

  test "find_or_create_from_scrape preserves original nom spelling" do
    prof = Professor.find_or_create_from_scrape(nom: "Marie-Hélène Dupont")
    assert_equal "Marie-Hélène Dupont", prof.nom
    assert_equal "marie-helene dupont", prof.nom_normalise
  end

  # Callback tests
  test "callback sets nom_normalise automatically on create" do
    prof = Professor.create!(nom: "Stéphane Lefèvre")
    assert_equal "stephane lefevre", prof.nom_normalise
  end

  test "callback updates nom_normalise when nom changes" do
    prof = Professor.create!(nom: "Marie")
    assert_equal "marie", prof.nom_normalise

    prof.update!(nom: "Marie Dupont")
    assert_equal "marie dupont", prof.nom_normalise
  end

  # Validation tests
  test "requires nom to be present" do
    prof = Professor.new(email: "test@example.com")
    assert_not prof.valid?
    assert prof.errors[:nom].any?
  end

  test "allows creation with just nom" do
    prof = Professor.create!(nom: "Test Prof")
    assert prof.persisted?
  end

  # Uniqueness constraint tests
  test "prevents duplicate nom_normalise" do
    Professor.create!(nom: "Marie Dupont")

    exception = assert_raises(ActiveRecord::RecordNotUnique) do
      Professor.create!(nom: "marie dupont")
    end

    assert_match(/nom_normalise/i, exception.message)
  end

  test "allows same original nom with different normalization (edge case)" do
    # Ce test vérifie que deux noms qui se normalisent différemment peuvent coexister
    prof1 = Professor.create!(nom: "Test 1")
    prof2 = Professor.create!(nom: "Test 2")

    assert_not_equal prof1.nom_normalise, prof2.nom_normalise
  end
end
