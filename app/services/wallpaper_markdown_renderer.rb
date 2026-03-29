class WallpaperMarkdownRenderer
  def initialize(markdown)
    @markdown = markdown.to_s.gsub("\r\n", "\n")
  end

  def render
    build_sections(parse_blocks).map { |section| render_section(section) }.join.html_safe
  end

  private

  attr_reader :markdown

  def parse_blocks
    lines = markdown.lines.map(&:chomp)
    blocks = []
    paragraph = []
    list = nil
    code = nil
    index = 0

    flush_paragraph = lambda do
      next if paragraph.empty?

      blocks << { type: :paragraph, text: paragraph.join(" ").strip }
      paragraph = []
    end

    flush_list = lambda do
      next unless list

      blocks << list
      list = nil
    end

    while index < lines.length
      line = lines[index]

      if code
        if line.start_with?("```")
          blocks << code
          code = nil
        else
          code[:lines] << line
        end
        index += 1
        next
      end

      if line.start_with?("```")
        flush_paragraph.call
        flush_list.call
        code = { type: :code, language: line.delete_prefix("```").strip, lines: [] }
        index += 1
        next
      end

      if line.strip.empty?
        flush_paragraph.call
        flush_list.call
        index += 1
        next
      end

      if line =~ /\A(#{Regexp.escape("#")}{1,3})\s+(.+)\z/
        flush_paragraph.call
        flush_list.call
        blocks << { type: :heading, level: Regexp.last_match(1).length, text: Regexp.last_match(2).strip }
        index += 1
        next
      end

      if line.strip == "---"
        flush_paragraph.call
        flush_list.call
        blocks << { type: :rule }
        index += 1
        next
      end

      if (table, consumed_lines = parse_table(lines, index))
        flush_paragraph.call
        flush_list.call
        blocks << table
        index += consumed_lines
        next
      end

      if line =~ /\A[-*]\s+(.+)\z/
        flush_paragraph.call
        list ||= { type: :list, ordered: false, items: [] }
        list[:items] << Regexp.last_match(1).strip
        index += 1
        next
      end

      if line =~ /\A\d+\.\s+(.+)\z/
        flush_paragraph.call
        list ||= { type: :list, ordered: true, items: [] }
        list[:items] << Regexp.last_match(1).strip
        index += 1
        next
      end

      flush_list.call
      paragraph << line.strip
      index += 1
    end

    blocks << code if code
    flush_paragraph.call
    flush_list.call
    blocks
  end

  def render_section(section)
    heading = section[:heading]
    body = section[:blocks].map { |block| render_block(block) }.join
    heading_html = heading ? "<h#{heading[:level]}>#{inline(heading[:text])}</h#{heading[:level]}>" : ""

    "<section class=\"sheet-section\">#{heading_html}#{body}</section>"
  end

  def render_block(block)
    case block[:type]
    when :paragraph
      "<div class=\"sheet-block\"><p>#{inline(block[:text])}</p></div>"
    when :list
      tag = block[:ordered] ? "ol" : "ul"
      items = block[:items].map { |item| "<li>#{inline(item)}</li>" }.join
      "<div class=\"sheet-block\"><#{tag}>#{items}</#{tag}></div>"
    when :code
      language = ERB::Util.html_escape(block[:language])
      code = ERB::Util.html_escape(block[:lines].join("\n"))
      label = language.empty? ? "" : "<div class=\"code-language\">#{language}</div>"
      "<div class=\"sheet-block sheet-code\">#{label}<pre><code>#{code}</code></pre></div>"
    when :table
      render_table(block)
    when :rule
      "<div class=\"sheet-block\"><hr></div>"
    else
      ""
    end
  end

  def inline(text)
    escaped = ERB::Util.html_escape(text)
    code_placeholders = []
    with_codes = escaped.gsub(/`([^`]+)`/) do
      code_placeholders << "<code>#{$1}</code>"
      "__CODE_PLACEHOLDER_#{code_placeholders.length - 1}__"
    end

    formatted = with_codes.gsub(/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    formatted.gsub(/__CODE_PLACEHOLDER_(\d+)__/) { code_placeholders[Regexp.last_match(1).to_i] }
  end

  def parse_table(lines, start_index)
    header_line = lines[start_index]
    divider_line = lines[start_index + 1]
    return unless header_line && divider_line
    return unless table_row?(header_line) && table_divider?(divider_line)

    header = split_table_row(header_line)
    alignments = split_table_row(divider_line).map { |cell| parse_alignment(cell) }
    return if header.empty? || header.length != alignments.length

    rows = []
    consumed_lines = 2
    cursor = start_index + 2

    while cursor < lines.length && table_row?(lines[cursor])
      row = split_table_row(lines[cursor])
      break if row.length != header.length

      rows << row
      consumed_lines += 1
      cursor += 1
    end

    [{ type: :table, header: header, alignments: alignments, rows: rows }, consumed_lines]
  end

  def render_table(block)
    headers = block[:header].each_with_index.map do |cell, index|
      "<th#{alignment_attr(block[:alignments][index])}>#{inline(cell)}</th>"
    end.join

    rows = block[:rows].map do |row|
      cells = row.each_with_index.map do |cell, index|
        "<td#{alignment_attr(block[:alignments][index])}>#{inline(cell)}</td>"
      end.join
      "<tr>#{cells}</tr>"
    end.join

    "<div class=\"sheet-block sheet-table\"><table><thead><tr>#{headers}</tr></thead><tbody>#{rows}</tbody></table></div>"
  end

  def build_sections(blocks)
    sections = []
    current_section = { heading: nil, blocks: [] }

    blocks.each do |block|
      if block[:type] == :heading
        if current_section[:heading] || current_section[:blocks].any?
          sections << current_section
        end
        current_section = { heading: block, blocks: [] }
      else
        current_section[:blocks] << block
      end
    end

    sections << current_section if current_section[:heading] || current_section[:blocks].any?
    sections
  end

  def alignment_attr(alignment)
    return "" unless alignment

    " class=\"align-#{alignment}\""
  end

  def table_row?(line)
    stripped = line.to_s.strip
    stripped.include?("|") && !stripped.start_with?("| ---")
  end

  def table_divider?(line)
    cells = split_table_row(line)
    cells.any? && cells.all? { |cell| cell.match?(/\A:?-{3,}:?\z/) }
  end

  def split_table_row(line)
    line.to_s.strip.sub(/\A\|/, "").sub(/\|\z/, "").split("|").map(&:strip)
  end

  def parse_alignment(cell)
    return :center if cell.start_with?(":") && cell.end_with?(":")
    return :left if cell.start_with?(":")
    return :right if cell.end_with?(":")

    nil
  end
end
