module WallpaperOptions
  SIZE_PRESETS = {
    "1920x1080" => { width: 1920, height: 1080, label: "FHD" },
    "2560x1440" => { width: 2560, height: 1440, label: "QHD" },
    "3840x2160" => { width: 3840, height: 2160, label: "4K UHD" }
  }.freeze

  THEMES = %w[light dark].freeze
  DENSITIES = %w[normal dense].freeze
  COLUMN_RANGE = (1..4)
  TRANSLATION_TARGET_LOCALES = {
    "en" => "English",
    "ja" => "日本語"
  }.freeze

  SAMPLE_MARKDOWN = <<~MARKDOWN.freeze
    # Rails Cheat Sheet

    ## Console
    - `bin/rails console`
    - `bin/rails routes`
    - `bin/rails db:migrate`

    ## Common Patterns
    - Keep controllers thin
    - Move branching logic into POROs
    - Prefer query objects for dense filtering

    ## Active Record
    ```ruby
    scope :recent, -> { where(created_at: 7.days.ago..) }

    User.includes(:profile)
        .recent
        .order(last_seen_at: :desc)
        .limit(20)
    ```

    ## Production Notes
    - Cache read-heavy endpoints first
    - Watch N+1 queries in views
    - Log request IDs for incident tracing

    ---

    ## Keyboard
    - Search files: `rg keyword`
    - Run tests: `bin/rails test`
    - Tail logs: `tail -f log/development.log`
  MARKDOWN

  module_function

  def normalize(raw_params)
    size_key = raw_params["canvas_size"].presence
    preset = SIZE_PRESETS[size_key] || SIZE_PRESETS["1920x1080"]
    columns = raw_params["columns"].to_i

    {
      title: raw_params["title"].presence || "Markdown Cheat Sheet",
      markdown: raw_params["markdown"].presence || SAMPLE_MARKDOWN,
      source_markdown: raw_params["source_markdown"].presence,
      canvas_size: size_key || "1920x1080",
      width: preset[:width],
      height: preset[:height],
      columns: COLUMN_RANGE.cover?(columns) ? columns : default_columns_for(size_key || "1920x1080"),
      theme: THEMES.include?(raw_params["theme"]) ? raw_params["theme"] : "light",
      density: DENSITIES.include?(raw_params["density"]) ? raw_params["density"] : "normal",
      target_locale: normalized_target_locale(raw_params["target_locale"])
    }
  end

  def default_columns_for(size_key)
    case size_key
    when "3840x2160" then 4
    when "2560x1440" then 3
    else 2
    end
  end

  def normalized_target_locale(target_locale)
    TRANSLATION_TARGET_LOCALES.key?(target_locale) ? target_locale : "en"
  end
end
