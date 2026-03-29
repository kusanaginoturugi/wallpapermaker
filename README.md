# Wallpapermaker

Markdown で書いた技術メモやチートシートを、PC 向け壁紙 PNG に変換する Rails アプリです。

## MVP 機能

- Markdown 入力とプレビュー
- 壁紙サイズ切替: `1920x1080`, `2560x1440`, `3840x2160`
- 段組切替: `1-4 columns`
- テーマ切替: `light`, `dark`
- 密度切替: `normal`, `dense`
- headless Chromium による PNG 出力

## 起動

```bash
bin/setup
bin/rails server
```

ブラウザで `http://localhost:3000` を開くと、編集画面とプレビューを確認できます。

## PNG 出力要件

PNG 書き出しには headless 実行可能な `chromium` が必要です。
この実装では `/usr/bin/chromium` を優先して利用します。

## テスト

```bash
bin/rails test test/services/wallpaper_markdown_renderer_test.rb
```

コントローラテストは、この環境では test DB 初期化時に `schema_migrations already exists` で失敗しました。DB 周りを整えた後に再実行してください。
