class CreateWallpaperTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :wallpaper_templates do |t|
      t.string :title, null: false
      t.string :canvas_size, null: false
      t.integer :columns, null: false
      t.string :theme, null: false
      t.string :density, null: false
      t.string :target_locale
      t.text :markdown, null: false
      t.text :source_markdown

      t.timestamps
    end
  end
end
