class HtmlDiffer
  def self.compare(old_html, new_html)
    # Normalize HTML first (remove whitespace differences, comments)
    normalized_old = normalize_html(old_html)
    normalized_new = normalize_html(new_html)

    return { changed: false, diff: nil } if normalized_old == normalized_new

    # Generate diff
    diff_output = generate_diff(normalized_old, normalized_new)

    {
      changed: true,
      diff: diff_output,
      changements_detectes: extract_changes(diff_output)
    }
  end

  private

  def self.normalize_html(html)
    return "" if html.nil?

    # Remove HTML comments
    html = html.gsub(/<!--.*?-->/m, "")
    # Collapse multiple spaces/newlines
    html = html.gsub(/\s+/, " ")
    # Remove spaces between tags and content
    html = html.gsub(/>\s+/, ">").gsub(/\s+</, "<")
    # Remove trailing/leading whitespace
    html.strip
  end

  def self.generate_diff(old_html, new_html)
    # Use Diffy gem for diff algorithm
    require "diffy"
    Diffy::Diff.new(old_html, new_html, context: 3).to_s(:html)
  end

  def self.extract_changes(diff_output)
    # Parse diff output to extract structured change information
    # Returns JSON-serializable hash for changements_detectes column
    {
      lines_added: count_additions(diff_output),
      lines_removed: count_deletions(diff_output),
      timestamp: Time.current.iso8601
    }
  end

  def self.count_additions(diff_output)
    diff_output.scan(/\+/).count
  end

  def self.count_deletions(diff_output)
    diff_output.scan(/-/).count
  end
end
