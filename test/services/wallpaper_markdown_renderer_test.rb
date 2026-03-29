require "test_helper"

class WallpaperMarkdownRendererTest < ActiveSupport::TestCase
  test "renders supported markdown blocks" do
    html = WallpaperMarkdownRenderer.new(<<~MARKDOWN).render
      # Title

      paragraph with `inline code` and **copy_and_clear_or_interrupt**

      - one
      - two

      | Action | Shortcut |
      | :----- | -------: |
      | New tab | ctrl+shift+t |
      | Close tab | ctrl+shift+q |

      ```ruby
      puts "ok"
      ```
    MARKDOWN

    assert_includes html, "<h1>Title</h1>"
    assert_includes html, "<code>inline code</code>"
    assert_includes html, "<strong>copy_and_clear_or_interrupt</strong>"
    assert_includes html, "<ul><li>one</li><li>two</li></ul>"
    assert_includes html, "<table>"
    assert_includes html, "<section class=\"sheet-section\"><h1>Title</h1><div class=\"sheet-block\"><p>paragraph with <code>inline code</code> and <strong>copy_and_clear_or_interrupt</strong></p></div><div class=\"sheet-block\"><ul><li>one</li><li>two</li></ul></div><div class=\"sheet-block sheet-table\">"
    assert_includes html, "<th class=\"align-left\">Action</th>"
    assert_includes html, "<th class=\"align-right\">Shortcut</th>"
    assert_includes html, "<td class=\"align-right\">ctrl+shift+t</td>"
    assert_includes html, "<div class=\"code-language\">ruby</div>"
  end
end
