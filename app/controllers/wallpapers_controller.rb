class WallpapersController < ApplicationController
  def new
    @wallpaper = selected_wallpaper
    render_editor
  end

  def preview
    @wallpaper = normalized_wallpaper_params
    response_status = process_wallpaper_action
    render_editor status: response_status
  rescue WallpaperTranslator::TranslationError, ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render_editor status: :unprocessable_entity
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
    render_editor status: :unprocessable_entity
  end

  private

  def render_editor(status: :ok)
    @saved_wallpapers = WallpaperTemplate.order(updated_at: :desc).limit(20)
    @preview_html = WallpaperMarkdownRenderer.new(@wallpaper[:markdown]).render
    render :new, status: status
  end

  def normalized_wallpaper_params
    wallpaper = WallpaperOptions.normalize(params.permit(:title, :markdown, :source_markdown, :canvas_size, :columns, :theme, :density, :target_locale).to_h)
    wallpaper[:wallpaper_template_id] = params[:wallpaper_template_id].presence
    wallpaper
  end

  def selected_wallpaper
    template = WallpaperTemplate.find_by(id: params[:template_id])
    wallpaper = if template
      WallpaperOptions.normalize(template.to_wallpaper_attributes)
    else
      normalized_wallpaper_params
    end

    if params[:duplicate].present?
      wallpaper[:wallpaper_template_id] = nil
    elsif template
      wallpaper[:wallpaper_template_id] = template.id
    end

    wallpaper
  end

  def process_wallpaper_action
    case params[:wallpaper_action]
    when "translate"
      @wallpaper[:source_markdown] = @wallpaper[:markdown]
      @wallpaper[:markdown] = WallpaperTranslator.new(
        markdown: @wallpaper[:source_markdown],
        target_locale: @wallpaper[:target_locale]
      ).translate
      flash.now[:notice] = "Markdown を翻訳しました"
      :ok
    when "save"
      save_wallpaper
    when "duplicate_save"
      save_wallpaper(force_create: true)
    else
      :ok
    end
  end

  def save_wallpaper(force_create: false)
    template = if !force_create && @wallpaper[:wallpaper_template_id].present?
      wallpaper_template = WallpaperTemplate.find(@wallpaper[:wallpaper_template_id])
      wallpaper_template.update!(template_params(@wallpaper))
      flash.now[:notice] = "上書き保存しました"
      wallpaper_template
    else
      flash.now[:notice] = "保存しました"
      WallpaperTemplate.create!(template_params(@wallpaper))
    end

    @wallpaper[:wallpaper_template_id] = template.id
    :ok
  end

  def template_params(wallpaper)
    wallpaper.slice(:title, :markdown, :source_markdown, :canvas_size, :columns, :theme, :density, :target_locale)
  end
end
