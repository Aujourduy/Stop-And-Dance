class HtmlCleaner
  def self.clean_and_convert(html)
    doc = Nokogiri::HTML(html)

    # 1. Extract data-attributes BEFORE cleaning (structured data)
    data_attrs = extract_data_attributes(doc)

    # 2. Remove noise (scripts, styles, navigation, etc.)
    doc.css('script, style, noscript, iframe, svg, link, meta').remove
    doc.css('nav, footer, aside, header[role="banner"], [hidden]').remove
    doc.css('[class*="cookie"], [class*="track"], [class*="analytics"]').remove

    # 3. Convert to Markdown (much more compact and Claude-friendly)
    markdown = ReverseMarkdown.convert(doc.to_html, unknown_tags: :bypass)

    {
      markdown: markdown,
      data_attributes: data_attrs,
      original_size_kb: (html.bytesize / 1024.0).round(2),
      markdown_size_kb: (markdown.bytesize / 1024.0).round(2),
      reduction_percent: ((1 - markdown.bytesize.to_f / html.bytesize) * 100).round(1)
    }
  end

  private

  def self.extract_data_attributes(doc)
    # Extract structured data from common data-* attributes
    data = {
      events: [],
      dates: [],
      prices: [],
      locations: []
    }

    # Look for event-related data attributes
    doc.css('[data-event], [data-date], [data-start], [data-end]').each do |node|
      event_data = {}
      node.attributes.each do |name, attr|
        next unless name.start_with?('data-')
        key = name.sub('data-', '').to_sym
        event_data[key] = attr.value
      end
      data[:events] << event_data if event_data.any?
    end

    # Extract dates
    doc.css('[data-date], [data-calendar-date], [datetime]').each do |node|
      data[:dates] << (node['data-date'] || node['data-calendar-date'] || node['datetime'])
    end

    # Extract prices
    doc.css('[data-price], [data-cost]').each do |node|
      data[:prices] << (node['data-price'] || node['data-cost'])
    end

    # Extract locations
    doc.css('[data-location], [data-venue], [data-place]').each do |node|
      data[:locations] << (node['data-location'] || node['data-venue'] || node['data-place'])
    end

    # Clean up empty arrays
    data.reject { |_k, v| v.empty? }
  end
end
