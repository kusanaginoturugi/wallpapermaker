class WallpaperTranslator
  class TranslationError < StandardError; end

  PROMPT = <<~PROMPT.freeze
    Translate the user's Markdown into the requested target language.

    Requirements:
    - Preserve valid Markdown structure.
    - Do not translate fenced code blocks.
    - Do not translate inline code spans.
    - Preserve headings, lists, tables, blockquotes, and emphasis markers.
    - Return only the translated Markdown body.
  PROMPT

  def initialize(markdown:, target_locale:)
    @markdown = markdown.to_s
    @target_locale = target_locale
  end

  def translate
    raise TranslationError, "Markdown が空です" if markdown.blank?
    if markdown.length > WallpaperOptions::MAX_TRANSLATION_CHARS
      raise TranslationError, "翻訳対象が長すぎます。#{WallpaperOptions::MAX_TRANSLATION_CHARS}文字以内にしてください"
    end
    raise TranslationError, "OPENAI_API_KEY が未設定です" if ENV["OPENAI_API_KEY"].blank?

    response = client.responses.create(
      model: "gpt-5-mini",
      input: [
        { role: "system", content: PROMPT },
        { role: "user", content: user_prompt }
      ]
    )

    translated = extract_text(response)
    raise TranslationError, "翻訳結果を取得できませんでした" if translated.blank?

    translated
  rescue OpenAI::Errors::RateLimitError => e
    raise TranslationError, rate_limit_message(e)
  rescue OpenAI::Errors::APIError, OpenAI::Errors::Error => e
    raise TranslationError, "翻訳に失敗しました: #{e.message}"
  end

  private

  attr_reader :markdown, :target_locale

  def client
    @client ||= OpenAI::Client.new(api_key: ENV["OPENAI_API_KEY"])
  end

  def user_prompt
    <<~PROMPT
      Target language: #{target_locale}

      Markdown:
      #{markdown}
    PROMPT
  end

  def extract_text(response)
    return response.output_text.to_s.strip if response.respond_to?(:output_text) && response.output_text.present?

    Array(response.output).filter_map do |item|
      next unless item.respond_to?(:type) && item.type == "message"

      Array(item.content).filter_map do |content|
        next unless content.respond_to?(:type) && content.type == "output_text"

        content.respond_to?(:text) ? content.text : nil
      end.join
    end.join.strip
  end

  def rate_limit_message(error)
    if error.message.to_s.include?("insufficient_quota")
      "OpenAI API の利用上限に達しています。Platform の billing / quota を確認してください。"
    else
      "OpenAI API のレート制限に達しました。少し待ってから再試行してください。"
    end
  end
end
