require "test_helper"

class WallpaperTranslatorTest < ActiveSupport::TestCase
  test "rejects markdown over translation limit before calling api" do
    markdown = "a" * (WallpaperOptions::MAX_TRANSLATION_CHARS + 1)

    error = assert_raises(WallpaperTranslator::TranslationError) do
      WallpaperTranslator.new(markdown: markdown, target_locale: "ja").translate
    end

    assert_includes error.message, WallpaperOptions::MAX_TRANSLATION_CHARS.to_s
  end
end
