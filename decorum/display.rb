module Decorum
  module Display
    TEMPLATE_PLACEHOLDER = "X"
    TEMPLATES = {
      lamp: <<~STR,
         /‾\\ 
        └ X ┘
         ─┴─ 
      STR
      curio: <<~STR,
         /◠\\ 
        | X |
        └───┘
      STR
      wall_hanging: <<~STR,
        ┌-◠-┐
        │ X │
        └───┘
      STR
    }

    def self.template(key, value)
      TEMPLATES[key].sub(TEMPLATE_PLACEHOLDER, value)
    end

    def self.header(text, left: "==[", right: "]==", width: 0)
      rem_width = width - left.size - right.size

      size = Rainbow.uncolor(text).size
      total_padding = rem_width - size

      if total_padding > 0
        half = total_padding / 2
        left += " " * half
        right = " " * (total_padding - half) + right
      end

      "#{left}#{text}#{right}"
    end

    def self.join_horizontally(strings, delimiter: " ")
      lines = strings.map { |s| s.split("\n") }
      max_width = lines.map(&:size).max
      # this logic is likely flawed, but it seems to work for now
      lines.map! { |line| line + [" "] * (max_width - line.size) } # pad lines
      lines.transpose.map { |lines| lines.join(delimiter) }.join("\n")
    end

  end
end