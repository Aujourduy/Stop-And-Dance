require "test_helper"

class NewsletterTest < ActiveSupport::TestCase
  test "valid newsletter with email" do
    newsletter = Newsletter.new(email: "test@example.com")
    assert newsletter.valid?
  end

  test "invalid without email" do
    newsletter = Newsletter.new(email: nil)
    assert_not newsletter.valid?
    assert newsletter.errors[:email].any?
  end

  test "invalid with malformed email" do
    newsletter = Newsletter.new(email: "invalid-email")
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:email], "n'est pas valide"
  end

  test "email must be unique (case-insensitive)" do
    Newsletter.create!(email: "test@example.com")
    duplicate = Newsletter.new(email: "TEST@example.com")
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  test "sets consenti_at timestamp on creation" do
    newsletter = Newsletter.create!(email: "test@example.com")
    assert_not_nil newsletter.consenti_at
    assert_in_delta Time.current, newsletter.consenti_at, 1.second
  end

  test "defaults actif to true" do
    newsletter = Newsletter.create!(email: "test@example.com")
    assert newsletter.actif
  end

  test "actifs scope returns only active newsletters" do
    active = Newsletter.create!(email: "active@example.com", actif: true)
    inactive = Newsletter.create!(email: "inactive@example.com", actif: false)

    assert_includes Newsletter.actifs, active
    assert_not_includes Newsletter.actifs, inactive
  end

  test "recent scope orders by created_at desc" do
    old = Newsletter.create!(email: "old@example.com")
    new_record = Newsletter.create!(email: "new@example.com")

    recent_list = Newsletter.recent.to_a
    assert_equal new_record, recent_list.first
    assert_equal old, recent_list.last
  end

  test "does not override consenti_at if already set" do
    custom_time = 1.day.ago
    newsletter = Newsletter.create!(email: "test@example.com", consenti_at: custom_time)
    assert_equal custom_time.to_i, newsletter.consenti_at.to_i
  end
end
