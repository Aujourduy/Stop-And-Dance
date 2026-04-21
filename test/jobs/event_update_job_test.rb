require "test_helper"

class EventUpdateJobTest < ActiveJob::TestCase
  def setup
    @job = EventUpdateJob.new
  end

  # --- suspicious_hour? ---

  test "heure valide 10h-18h n'est pas suspecte" do
    debut = Time.zone.parse("2026-04-28 10:00")
    fin = Time.zone.parse("2026-04-28 18:00")
    assert_not @job.send(:suspicious_hour?, debut, fin)
  end

  test "heure tôt matin (6h) est suspecte" do
    debut = Time.zone.parse("2026-04-28 06:00")
    fin = Time.zone.parse("2026-04-28 08:00")
    assert @job.send(:suspicious_hour?, debut, fin)
  end

  test "heure 23h est suspecte (cas Garance Marseille)" do
    debut = Time.zone.parse("2026-04-27 23:00")
    fin = Time.zone.parse("2026-04-28 01:00")
    assert @job.send(:suspicious_hour?, debut, fin)
  end

  test "heure 22h limite reste acceptable" do
    debut = Time.zone.parse("2026-04-28 22:00")
    fin = Time.zone.parse("2026-04-29 00:00")
    # 22h limite : acceptable, mais heure_fin < heure_debut + wrap > 6h pas ici
    # 2h de durée : pas suspect pour soirée
    assert_not @job.send(:suspicious_hour?, debut, fin)
  end

  test "heure 7h est acceptable" do
    debut = Time.zone.parse("2026-04-28 07:00")
    fin = Time.zone.parse("2026-04-28 09:00")
    assert_not @job.send(:suspicious_hour?, debut, fin)
  end

  test "heure_fin avant heure_debut avec wrap > 6h est suspecte" do
    # Debut 20h, fin 04h le lendemain = 8h de wrap → suspect
    debut = Time.zone.parse("2026-04-28 20:00")
    fin = Time.zone.parse("2026-04-28 04:00")
    assert @job.send(:suspicious_hour?, debut, fin)
  end

  test "heure_fin avant heure_debut avec wrap court acceptable (soirée tardive)" do
    # Debut 21h, fin 00h00 lendemain = 3h → acceptable (événement soirée)
    debut = Time.zone.parse("2026-04-28 21:00")
    fin = Time.zone.parse("2026-04-28 00:00")
    assert_not @job.send(:suspicious_hour?, debut, fin)
  end
end
