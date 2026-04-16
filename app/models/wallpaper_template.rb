class WallpaperTemplate < ApplicationRecord
  validates :title, presence: true
  validates :markdown, presence: true
  validates :canvas_size, inclusion: { in: WallpaperOptions::SIZE_PRESETS.keys }
  validates :columns, inclusion: { in: WallpaperOptions::COLUMN_RANGE }
  validates :theme, inclusion: { in: WallpaperOptions::THEMES }
  validates :density, inclusion: { in: WallpaperOptions::DENSITIES }
  validates :target_locale, inclusion: { in: WallpaperOptions::TRANSLATION_TARGET_LOCALES.keys }, allow_nil: true

  def to_wallpaper_attributes
    {
      "wallpaper_template_id" => id,
      "title" => title,
      "markdown" => markdown,
      "source_markdown" => source_markdown,
      "canvas_size" => canvas_size,
      "columns" => columns,
      "theme" => theme,
      "density" => density,
      "target_locale" => target_locale
    }
  end
end
