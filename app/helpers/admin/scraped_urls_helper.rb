module Admin::ScrapedUrlsHelper
  def render_markdown(markdown_text)
    return "" if markdown_text.blank?

    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,     # Security: filter raw HTML in Markdown
      no_styles: true,       # Security: no inline styles
      safe_links_only: true, # Security: only safe protocols (http, https, mailto)
      hard_wrap: true        # UX: preserve line breaks
    )

    markdown = Redcarpet::Markdown.new(renderer,
      autolink: true,                # Auto-link URLs
      tables: true,                  # Support tables
      fenced_code_blocks: true,      # Support ```code```
      strikethrough: true,           # Support ~~text~~
      space_after_headers: true      # Require space after #
    )

    markdown.render(markdown_text).html_safe
  end
end
