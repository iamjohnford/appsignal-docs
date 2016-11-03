# From: https://github.com/hashicorp/middleman-hashicorp/blob/master/lib/middleman-hashicorp/redcarpet.rb

require "middleman-core"
require "middleman-core/renderers/redcarpet"
require "active_support/core_ext/module/attribute_accessors"

class AppsignalMarkdown < Middleman::Renderers::MiddlemanRedcarpetHTML
  OPTIONS = {
    :autolink           => true,
    :fenced_code_blocks => true,
    :no_intra_emphasis  => true,
    :strikethrough      => true,
    :tables             => true,
  }.freeze

  # Initialize with correct config.
  # Does not get config from `set :markdown` from `config.rb`
  def initialize(options = {})
    super(options.merge(OPTIONS))
  end

  # Parse contents of every paragraph for custom tags and render paragraph.
  def paragraph(text)
    add_custom_tags("<p>#{text.strip}</p>\n")
  end

  # Add anchor tags to every heading.
  # Create a link from the heading.
  def header(text, level)
    anchor = text.parameterize
    %(<h%s id="%s"><a href="#%s">%s</a></h%s>) % [level, anchor, anchor, text, level]
  end

  def preprocess(doc)
    doc.gsub(/([a-z]+)> (.+)$/) do
      type = $1
      value = $2
      case type
      when "gem"
        <<-TAG.strip
          <div class="custom-tag ruby-gem">
            <span class="label">Ruby gem:</span>
            <span class="value">#{value}</span>
          </div>
        TAG
      when "type"
        <<-TAG.strip
          <div class="custom-tag value-type">
            <span class="label">Type:</span>
            <span class="value">#{value}</span>
          </div>
        TAG
      when "default"
        <<-TAG.strip
          <div class="custom-tag default-value">
            <span class="label">Default:</span>
            <span class="value">#{value}</span>
          </div>
        TAG
      else
        <<-TAG.strip
          <div class="custom-tag tag-#{type}">
            <span class="value">#{value}</span>
          </div>
        TAG
      end
    end
  end

  private

  # Add custom tags to content
  def add_custom_tags(text)
    map = { "-&gt;" => "notice" }
    regexp = map.map { |k, _| Regexp.escape(k) }.join("|")

    md = text.match(/^<p>(#{regexp})/)
    return text unless md

    key = md.captures[0]
    klass = map[key]
    text.gsub!(/#{Regexp.escape(key)}\s+?/, "")

    <<-EOH.gsub(/^ {8}/, "")
      <div class="#{klass}">#{text}</div>
    EOH
  end
end
