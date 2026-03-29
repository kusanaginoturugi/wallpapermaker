class WallpapersController < ApplicationController
  def new
    @wallpaper = normalized_wallpaper_params
    @preview_html = WallpaperMarkdownRenderer.new(@wallpaper[:markdown]).render
  end

  def export
    wallpaper = normalized_wallpaper_params
    exporter = WallpaperExporter.new(wallpaper)
    png = exporter.export

    send_data png,
      filename: exporter.filename,
      type: "image/png",
      disposition: :attachment
  rescue WallpaperExporter::ExportError => e
    flash.now[:alert] = e.message
    @wallpaper = wallpaper
    @preview_html = WallpaperMarkdownRenderer.new(@wallpaper[:markdown]).render
    render :new, status: :unprocessable_entity
  end

  private

  def normalized_wallpaper_params
    WallpaperOptions.normalize(params.permit(:title, :markdown, :canvas_size, :columns, :theme, :density).to_h)
  end
end
