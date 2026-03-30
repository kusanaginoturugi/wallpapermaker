class WallpapersController < ApplicationController
  def new
    @wallpaper = normalized_wallpaper_params
    @preview_html = WallpaperMarkdownRenderer.new(@wallpaper[:markdown]).render
  end

  def preview
    @wallpaper = normalized_wallpaper_params
    response_status = process_wallpaper_action
    @preview_html = WallpaperMarkdownRenderer.new(@wallpaper[:markdown]).render

    render :new, status: response_status
  rescue WallpaperTranslator::TranslationError, ActiveRecord::RecordInvalid => e
    @preview_html = WallpaperMarkdownRenderer.new(@wallpaper[:markdown]).render
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
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
    WallpaperOptions.normalize(params.permit(:title, :markdown, :source_markdown, :canvas_size, :columns, :theme, :density, :target_locale).to_h)
  end

  def process_wallpaper_action
    case params[:wallpaper_action]
    when "translate"
      @wallpaper[:source_markdown] ||= @wallpaper[:markdown]
      @wallpaper[:markdown] = WallpaperTranslator.new(
        markdown: @wallpaper[:source_markdown],
        target_locale: @wallpaper[:target_locale]
      ).translate
      flash.now[:notice] = "Markdown を翻訳しました"
      :ok
    when "save"
      WallpaperTemplate.create!(template_params(@wallpaper))
      flash.now[:notice] = "保存しました"
      :created
    else
      :ok
    end
  end

  def template_params(wallpaper)
    wallpaper.slice(:title, :markdown, :source_markdown, :canvas_size, :columns, :theme, :density, :target_locale)
  end
end
