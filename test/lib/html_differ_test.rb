require "test_helper"

class HtmlDifferTest < ActiveSupport::TestCase
  test "returns unchanged when HTML is identical" do
    html = "<p>test</p>"
    result = HtmlDiffer.compare(html, html)

    assert_equal false, result[:changed]
    assert_nil result[:diff]
  end

  test "ignores whitespace differences" do
    old_html = "<p>test</p>"
    new_html = "<p>   test   </p>"
    result = HtmlDiffer.compare(old_html, new_html)

    assert_equal false, result[:changed]
  end

  test "ignores HTML comments" do
    old_html = "<!-- comment --><p>test</p>"
    new_html = "<p>test</p>"
    result = HtmlDiffer.compare(old_html, new_html)

    assert_equal false, result[:changed]
  end

  test "detects real content changes" do
    old_html = "<p>old content</p>"
    new_html = "<p>new content</p>"
    result = HtmlDiffer.compare(old_html, new_html)

    assert_equal true, result[:changed]
    assert_not_nil result[:diff]
    assert_not_nil result[:changements_detectes]
    assert result[:changements_detectes].key?(:timestamp)
  end

  test "handles nil HTML gracefully" do
    result = HtmlDiffer.compare(nil, "<p>test</p>")

    assert_equal true, result[:changed]
  end
end
