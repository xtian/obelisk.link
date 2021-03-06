# frozen_string_literal: true

class Markdowner
  # opts[:allow_images] allows <img> tags

  def initialize(text, opts)
    @text = text
    @allow_images = opts[:allow_images]
  end

  def self.to_html(text, opts = {})
    new(text, opts).to_html
  end

  def to_html
    return '' if text.blank?

    exts = %i[tagfilter autolink strikethrough]
    root = CommonMarker.render_doc(text.to_s, [:SMART], exts)

    walk_text_nodes(root) { |n| postprocess_text_node(n) }

    ng = Nokogiri::HTML(root.to_html([:SAFE], exts))

    # change <h1>, <h2>, etc. headings to just bold tags
    ng.css('h1, h2, h3, h4, h5, h6').each do |h|
      h.name = 'strong'
    end

    ng.css('img').remove unless allow_images?

    # make links have rel=nofollow
    ng.css('a').each do |h|
      h[:rel] = 'nofollow' unless begin
                                     URI.parse(h[:href]).host.nil?
                                   rescue StandardError
                                     false
                                   end
    end

    if ng.at_css('body')
      ng.at_css('body').inner_html
    else
      ''
    end
  end

  private

  attr_reader :text

  def allow_images?
    @allow_images
  end

  def walk_text_nodes(node, &block)
    return if node.type == :link
    return yield(node) if node.type == :text

    node.each do |child|
      walk_text_nodes(child, &block)
    end
  end

  def postprocess_text_node(node)
    while node
      return unless node.string_content =~ /\B(@#{User::VALID_USERNAME})/

      before = $`
      user = Regexp.last_match(1)
      after = $'

      node.string_content = before

      if User.exists?(username: user[1..-1])
        link = CommonMarker::Node.new(:link)
        link.url = Rails.application.root_url + "u/#{user[1..-1]}"
        node.insert_after(link)

        link_text = CommonMarker::Node.new(:text)
        link_text.string_content = user
        link.append_child(link_text)

        node = link
      else
        node.string_content += user
      end

      if after.empty?
        node = nil
      else
        remainder = CommonMarker::Node.new(:text)
        remainder.string_content = after
        node.insert_after(remainder)

        node = remainder
      end
    end
  end
end
