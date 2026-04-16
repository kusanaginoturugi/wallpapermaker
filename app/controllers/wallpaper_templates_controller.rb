class WallpaperTemplatesController < ApplicationController
  def destroy
    WallpaperTemplate.find(params[:id]).destroy!

    redirect_to root_path, notice: "削除しました"
  end
end
