require "open3"
require "tempfile"

class WallpaperExporter
  class ExportError < StandardError; end

  CHROMIUM_CANDIDATES = %w[/usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome /usr/bin/google-chrome-stable].freeze

  attr_reader :wallpaper

  def initialize(wallpaper)
    @wallpaper = wallpaper
  end

  def export
    browser = chromium_path
    raise ExportError, "Chromium が見つかりません。PNG出力には headless Chromium が必要です。" unless browser

    html_file = Tempfile.new(["wallpaper", ".html"])
    png_file = Tempfile.new(["wallpaper", ".png"])
    html_file.write(document)
    html_file.flush

    command = [
      browser,
      "--headless",
      "--no-sandbox",
      "--disable-dev-shm-usage",
      "--disable-gpu",
      "--hide-scrollbars",
      "--force-device-scale-factor=1",
      "--virtual-time-budget=1000",
      "--window-size=#{wallpaper[:width]},#{wallpaper[:height]}",
      "--screenshot=#{png_file.path}",
      html_file.path
    ]

    _stdout, stderr, status = Open3.capture3(*command)
    raise ExportError, "PNG出力に失敗しました: #{stderr.presence || 'unknown error'}" unless status.success?

    File.binread(png_file.path)
  ensure
    html_file&.close!
    png_file&.close!
  end

  def filename
    base = wallpaper[:title].parameterize.presence || "wallpaper"
    "#{base}-#{wallpaper[:canvas_size]}.png"
  end

  private

  def chromium_path
    CHROMIUM_CANDIDATES.find { |path| File.exist?(path) }
  end

  def document
    ApplicationController.render(
      template: "wallpapers/export",
      assigns: {
        wallpaper: wallpaper,
        preview_html: WallpaperMarkdownRenderer.new(wallpaper[:markdown]).render
      },
      layout: false
    )
  end
end
