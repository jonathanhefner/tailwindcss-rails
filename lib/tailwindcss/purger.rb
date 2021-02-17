class Tailwindcss::Purger
  CLASS_NAME_PATTERN = /[:A-Za-z0-9_-]+[\.]*[\\\/:A-Za-z0-9_-]*/

  COMMENT = %r"/[*].*?[*]/"m
  COMMENT_OR_WHITESPACE = /\s*#{COMMENT}?\s*/
  TERMINATOR = /[{};]#{COMMENT_OR_WHITESPACE}\z/
  DISCARDABLE = /\A#{COMMENT_OR_WHITESPACE}\z/
  BLOCK_START = /\{\s*\z/
  BLOCK_END = /\A\s*\}/
  AT_RULE = /\A\s*@/
  NON_CLASS = /[^.\s,{]+/

  attr_reader :keep_these_class_names

  class << self
    def purge(input, keeping_class_names_from_files:)
      new(extract_class_names_from(keeping_class_names_from_files)).purge(input)
    end

    def extract_class_names(string)
      string.scan(CLASS_NAME_PATTERN).uniq.sort!
    end

    def extract_class_names_from(files)
      Array(files).flat_map { |file| extract_class_names(file.read) }.uniq.sort!
    end
  end

  def initialize(keep_these_class_names)
    @keep_these_class_names = keep_these_class_names
  end

  def purge(input)
    output = +""
    pending_line = nil
    @pending_output = []

    input.each_line do |line|
      line, pending_line = (pending_line << line), nil if pending_line

      if line.match?(TERMINATOR)
        process_line(line, output)
      elsif !line.match?(DISCARDABLE)
        pending_line = line
      end
    end

    output
  end

  private
    def selector_pattern
      @selector_pattern ||= begin
        classes = @keep_these_class_names.join("|").gsub(%r"[:./]") { |c| Regexp.escape "\\#{c}" }
        /(?:\A|,)(?:\s*(?:#{NON_CLASS}|[.](?:#{classes})(?=[:\s,{])))+(?=\s*[,{])/
      end
    end

    def process_line(line, output)
      line.gsub!(COMMENT, "") #????

      if BLOCK_START.match?(line)
        @pending_output << purge_block_start(line)
      elsif !@pending_output.empty? && BLOCK_END.match?(line)
        @pending_output.pop
      elsif @pending_output.last != ""
        output << @pending_output.shift until @pending_output.empty?
        output << line
      end
    end

    def purge_block_start(line)
      if AT_RULE.match?(line)
        line
      elsif !line.include?(",")
        selector_pattern.match?(line) ? line : ""
      else
        purged = line.scan(selector_pattern).join
        (purged << " {\n").delete_prefix!(",") unless purged.empty?
        purged
      end
    end
end
