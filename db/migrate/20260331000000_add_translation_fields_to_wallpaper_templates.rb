class AddTranslationFieldsToWallpaperTemplates < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:wallpaper_templates, :source_markdown)
      add_column :wallpaper_templates, :source_markdown, :text
    end

    unless column_exists?(:wallpaper_templates, :target_locale)
      add_column :wallpaper_templates, :target_locale, :string
    end
  end
end
