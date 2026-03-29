require "test_helper"

class WallpapersControllerTest < ActionDispatch::IntegrationTest
  test "renders wallpaper editor" do
    get root_url

    assert_response :success
    assert_includes response.body, "技術メモ壁紙ジェネレータ"
    assert_includes response.body, "Rails Cheat Sheet"
  end

  test "exports png wallpaper" do
    fake_exporter = Struct.new(:filename) do
      def export
        File.binread(Rails.root.join("public/icon.png"))
      end
    end.new("ruby-notes-1920x1080.png")

    WallpaperExporter.stub(:new, fake_exporter) do
      post export_wallpaper_url, params: {
        title: "Ruby Notes",
        markdown: "# Header\n- item",
        canvas_size: "1920x1080",
        columns: 2,
        theme: "light",
        density: "normal"
      }
    end

    assert_response :success
    assert_equal "image/png", response.media_type
    assert_includes response.headers["Content-Disposition"], "ruby-notes-1920x1080.png"
  end
end
