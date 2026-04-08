class RecurrenceExpander
  END_MONTH = 8
  END_DAY = 31

  DAY_MAP = {
    "monday" => 1, "tuesday" => 2, "wednesday" => 3, "thursday" => 4,
    "friday" => 5, "saturday" => 6, "sunday" => 0,
    "lundi" => 1, "mardi" => 2, "mercredi" => 3, "jeudi" => 4,
    "vendredi" => 5, "samedi" => 6, "dimanche" => 0
  }.freeze

  def self.expand(event_data)
    recurrence = event_data[:recurrence] || event_data["recurrence"]
    return [event_data] if recurrence.nil?

    recurrence = recurrence.transform_keys(&:to_s) if recurrence.is_a?(Hash)

    case recurrence["type"]
    when "weekly"
      expand_weekly(event_data, recurrence)
    else
      [event_data]
    end
  end

  private

  def self.expand_weekly(event_data, recurrence)
    day_name = recurrence["day_of_week"].to_s.downcase
    day_number = DAY_MAP[day_name]
    return [event_data] if day_number.nil?

    time_start = recurrence["time_start"] || "19:00"
    time_end = recurrence["time_end"] || "21:00"
    excluded = build_excluded_set(recurrence)
    end_date = calculate_end_date

    current = Date.current
    current += 1 until current.wday == day_number

    events = []
    while current <= end_date
      unless excluded.include?(current)
        event = deep_dup_event(event_data)
        # Remove recurrence from expanded event
        event.delete(:recurrence)
        event.delete("recurrence")

        tz_offset = Time.zone.parse(current.to_s).strftime("%:z")
        event[:date_debut] = "#{current}T#{time_start}:00#{tz_offset}"
        event[:date_fin] = "#{current}T#{time_end}:00#{tz_offset}"
        events << event
      end
      current += 7
    end

    events
  end

  def self.calculate_end_date
    today = Date.current
    end_date = Date.new(today.year, END_MONTH, END_DAY)
    end_date = Date.new(today.year + 1, END_MONTH, END_DAY) if today > end_date
    end_date
  end

  def self.build_excluded_set(recurrence)
    excluded = Set.new

    (recurrence["excluded_dates"] || []).each do |d|
      excluded.add(Date.parse(d))
    rescue Date::Error
      next
    end

    (recurrence["excluded_ranges"] || []).each do |range|
      from = Date.parse(range["from"])
      to = Date.parse(range["to"])
      (from..to).each { |d| excluded.add(d) }
    rescue Date::Error
      next
    end

    excluded
  end

  def self.deep_dup_event(event_data)
    event_data.each_with_object({}) do |(k, v), h|
      h[k] = v.is_a?(Array) ? v.dup : v
    end
  end
end
