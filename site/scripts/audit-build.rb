#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'date'
require 'json'
require 'pathname'
require 'rexml/document'
require 'time'
require 'uri'
require 'yaml'

SITE_ROOT = File.expand_path('..', __dir__)
PUBLIC_ROOT = File.join(SITE_ROOT, 'public')
PRODUCTION_HOSTS = %w[michaelsoprano.com www.michaelsoprano.com].freeze

SECTIONS = {
  'publications' => {
    public: 'publication',
    archive: 'publication',
    marker: 'legacy-publication-single',
    archive_marker: 'legacy-publication-archive',
    item_marker: 'pub-list-item view-citation'
  },
  'events' => {
    public: 'talk',
    archive: 'event',
    marker: 'legacy-event-single',
    archive_marker: 'legacy-event-archive',
    item_marker: 'media stream-item'
  },
  'blog' => {
    public: 'post',
    archive: 'post',
    marker: 'legacy-blog-single',
    archive_marker: 'legacy-blog-archive',
    item_marker: 'media stream-item'
  }
}.freeze

def load_page(path)
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  match = source.match(/\A---\r?\n(.*?)\r?\n---\r?\n/m)
  raise 'missing YAML front matter' unless match

  data = YAML.safe_load(match[1], permitted_classes: [Date, Time], aliases: true) || {}
  body = source[match.end(0)..].to_s.gsub("\r\n", "\n").rstrip
  [data, body]
end

def normalized(value)
  case value
  when Array
    value.map { |item| normalized(item) }
  when Hash
    value.transform_keys(&:to_s).transform_values { |item| normalized(item) }
  when Date, Time
    value.iso8601
  when String
    value.gsub(/\s+/, ' ').strip
  else
    value
  end
end

def html_text(html)
  CGI.unescapeHTML(
    html
      .gsub(/<script\b.*?<\/script>/mi, ' ')
      .gsub(/<style\b.*?<\/style>/mi, ' ')
      .gsub(/<[^>]+>/, ' ')
  ).gsub(/\s+/, ' ').strip
end

def source_text(source)
  CGI.unescapeHTML(source.to_s)
    .gsub(/!\[([^\]]*)\]\([^)]*\)/, '\\1')
    .gsub(/\[([^\]]+)\]\([^)]*\)/, '\\1')
    .gsub(/<[^>]+>/, ' ')
    .gsub(/[`*_~#>|]/, ' ')
    .gsub(/^\s*[-+]\s+/, ' ')
    .gsub(/\s+/, ' ')
    .strip
end

def significant_excerpt(value, length = 72)
  text = source_text(value)
  return nil if text.length < 20

  text[0, length].strip
end

def attribute_values(markup, names)
  pattern = /(?<![:\w-])(?:#{names.join('|')})\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i
  markup.scan(pattern).map { |double_quoted, single_quoted, unquoted| double_quoted || single_quoted || unquoted }
end

def element_attributes(html, element)
  html.scan(/<#{Regexp.escape(element)}\b[^>]*>/i)
end

def metadata_values(html, key)
  element_attributes(html, 'meta').each_with_object([]) do |meta, values|
    names = attribute_values(meta, %w[name property]).map(&:downcase)
    next unless names.include?(key.downcase)

    value = attribute_values(meta, %w[content]).first
    values << value unless value.nil?
  end
end

def links_with_rel(html, rel)
  element_attributes(html, 'link').select do |link|
    attribute_values(link, %w[rel]).flat_map { |value| value.downcase.split }.include?(rel.downcase)
  end
end

def json_ld_documents(html)
  html.scan(/<script\b([^>]*)>(.*?)<\/script>/mi).each_with_object([]) do |(attributes, body), documents|
    types = attribute_values(attributes, %w[type]).map(&:downcase)
    next unless types.include?('application/ld+json')

    documents << JSON.parse(body)
  end
end

def json_ld_types(documents)
  documents.flat_map do |document|
    entries = document.is_a?(Array) ? document : [document]
    entries.each_with_object([]) do |entry, types|
      type = entry.is_a?(Hash) ? entry['@type'] : nil
      types << type unless type.nil?
    end
  end.flatten
end

def html_url(path)
  relative = Pathname.new(path).relative_path_from(Pathname.new(PUBLIC_ROOT)).to_s
  return '/' if relative == 'index.html'

  relative = relative.delete_suffix('index.html')
  "/#{relative}"
end

def internal_location(raw_reference, source_path)
  reference = CGI.unescapeHTML(raw_reference.to_s.strip)
  return nil if reference.empty? || reference.start_with?('#', 'mailto:', 'tel:', 'javascript:', 'data:')

  reference = "https:#{reference}" if reference.start_with?('//')
  uri = URI.parse(reference)
  return nil if uri.host && !PRODUCTION_HOSTS.include?(uri.host.downcase)

  resolved = if uri.host
               uri
             else
               base = URI("https://michaelsoprano.com#{html_url(source_path)}")
               URI.join(base.to_s, reference)
             end

  decoded_path = URI::DEFAULT_PARSER.unescape(resolved.path.to_s)
  decoded_fragment = URI::DEFAULT_PARSER.unescape(resolved.fragment.to_s)
  [decoded_path.empty? ? '/' : decoded_path, decoded_fragment]
rescue URI::InvalidURIError, ArgumentError
  :invalid
end

def internal_reference(raw_reference, source_path)
  location = internal_location(raw_reference, source_path)
  return location if location.nil? || location == :invalid

  location.first
end

def target_candidates(path)
  clean_path = path.sub(%r{\A/+}, '')
  return [File.join(PUBLIC_ROOT, 'index.html')] if clean_path.empty?

  absolute = File.join(PUBLIC_ROOT, clean_path)
  [absolute, File.join(absolute, 'index.html')]
end

def target_exists?(path)
  target_candidates(path).any? { |candidate| File.file?(candidate) }
end

errors = []
warnings = []

unless Dir.exist?(PUBLIC_ROOT)
  warn "ERROR: #{PUBLIC_ROOT} does not exist; build the site first."
  exit 1
end

html_paths = Dir.glob(File.join(PUBLIC_ROOT, '**', '*.html')).sort
asset_paths = Dir.glob(File.join(PUBLIC_ROOT, '**', '*'), File::FNM_DOTMATCH).select { |path| File.file?(path) }
errors << 'no generated HTML pages found' if html_paths.empty?
errors << 'favicon.ico: missing generated compatibility favicon' unless File.file?(File.join(PUBLIC_ROOT, 'favicon.ico'))

home_path = File.join(PUBLIC_ROOT, 'index.html')
if File.file?(home_path)
  home_html = File.binread(home_path).force_encoding(Encoding::UTF_8)
  errors << 'index.html: missing favicon link' if links_with_rel(home_html, 'icon').empty?
  errors << 'index.html: missing Apple touch icon link' if links_with_rel(home_html, 'apple-touch-icon').empty?
  rss_links = links_with_rel(home_html, 'alternate').select do |link|
    attribute_values(link, %w[type]).any? { |type| type.casecmp('application/rss+xml').zero? }
  end
  errors << 'index.html: missing RSS discovery link' if rss_links.empty?
end

referenced_internal_paths = {}
html_paths.each do |path|
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  html = File.binread(path).force_encoding(Encoding::UTF_8)
  text = html_text(html)
  alias_page = html.match?(/<meta\b[^>]*\bhttp-equiv\s*=\s*["']?refresh["']?/i)
  link_markup = html
    .gsub(/<script\b.*?<\/script>/mi, ' ')
    .gsub(/<style\b.*?<\/style>/mi, ' ')

  errors << "#{relative}: missing or empty <title>" unless html.match?(/<title>\s*[^<]+\s*<\/title>/i)
  html_tag = html[/<html\b[^>]*>/i].to_s
  errors << "#{relative}: missing document language" if !alias_page && attribute_values(html_tag, %w[lang]).all?(&:empty?)
  has_viewport = html.scan(/<meta\b[^>]*>/i).any? do |meta|
    attribute_values(meta, %w[name]).any? { |name| name.casecmp('viewport').zero? }
  end
  errors << "#{relative}: missing viewport metadata" if !alias_page && !has_viewport
  errors << "#{relative}: unresolved Hugo template expression" if html.match?(/\{\{[<%\s.]/)
  errors << "#{relative}: page has no readable content" if !alias_page && relative != '404.html' && text.length < 40

  unless alias_page
    canonical_path = html_url(path).sub(%r{/page/\d+/$}, '/')
    expected_canonical = "https://michaelsoprano.com#{canonical_path}"
    canonical_urls = links_with_rel(html, 'canonical').flat_map { |link| attribute_values(link, %w[href]) }
    errors << "#{relative}: canonical URL is #{canonical_urls.inspect}, expected #{expected_canonical.inspect}" unless canonical_urls == [expected_canonical]
    errors << "#{relative}: missing favicon link" if links_with_rel(html, 'icon').empty?
    errors << "#{relative}: missing Apple touch icon link" if links_with_rel(html, 'apple-touch-icon').empty?

    {
      'og:site_name' => 'Michael Soprano',
      'og:url' => expected_canonical,
      'twitter:site' => '@Miccighel_',
      'twitter:creator' => '@Miccighel_'
    }.each do |key, expected|
      values = metadata_values(html, key)
      errors << "#{relative}: #{key} metadata is #{values.inspect}, expected #{expected.inspect}" unless values == [expected]
    end
    %w[og:title og:description twitter:card].each do |key|
      values = metadata_values(html, key)
      errors << "#{relative}: missing or empty #{key} metadata" if values.empty? || values.any?(&:empty?)
    end

    begin
      json_ld = json_ld_documents(html)
      errors << "#{relative}: missing JSON-LD structured data" if json_ld.empty?
      if JSON.generate(json_ld).match?(/"(?:url|image)":null/)
        errors << "#{relative}: JSON-LD contains a null URL or image"
      end
    rescue JSON::ParserError => e
      errors << "#{relative}: invalid JSON-LD structured data (#{e.message})"
    end
  end

  document_ids = attribute_values(html, %w[id])
  duplicate_ids = document_ids.group_by(&:itself).select { |_id, values| values.length > 1 }.keys
  duplicate_ids.each { |id| errors << "#{relative}: duplicate id #{id.inspect}" }

  html.scan(/<img\b[^>]*>/i).each do |image|
    errors << "#{relative}: image is missing an alt attribute" if attribute_values(image, %w[alt]).empty?
  end

  html.scan(/<a\b[^>]*\btarget\s*=\s*["']?_blank["']?[^>]*>/i).each do |anchor|
    rel_values = attribute_values(anchor, %w[rel]).flat_map { |value| value.downcase.split }
    errors << "#{relative}: external-window link is missing rel=noopener" unless rel_values.include?('noopener')
  end

  href_references = attribute_values(link_markup, %w[href])
  references = href_references + attribute_values(link_markup, %w[src poster data-cite-url])
  attribute_values(link_markup, %w[srcset]).each do |srcset|
    srcset.split(',').each { |candidate| references << candidate.strip.split(/\s+/, 2).first }
  end
  link_markup.scan(/\burl\(\s*["']?([^)'"\s]+)["']?\s*\)/i).flatten.each { |url| references << url }

  references.uniq.each do |reference|
    internal_path = internal_reference(reference, path)
    next if internal_path.nil?

    if internal_path == :invalid
      errors << "#{relative}: invalid URL #{reference.inspect}"
      next
    end

    referenced_internal_paths[internal_path] ||= []
    referenced_internal_paths[internal_path] << relative
    next if target_exists?(internal_path)

    errors << "#{relative}: missing internal target #{internal_path.inspect} (from #{reference.inspect})"
  end

  %w[og:image twitter:image].flat_map { |key| metadata_values(html, key) }.uniq.each do |reference|
    internal_path = internal_reference(reference, path)
    next if internal_path.nil?

    if internal_path == :invalid
      errors << "#{relative}: invalid social preview image URL #{reference.inspect}"
    elsif !target_exists?(internal_path)
      errors << "#{relative}: missing social preview image #{internal_path.inspect}"
    end
  end


  href_references.uniq.each do |reference|
    location = internal_location(reference, path)
    next if location.nil? || location == :invalid

    internal_path, fragment = location
    next if fragment.empty? || fragment.start_with?(':~:text=')

    target = target_candidates(internal_path).find { |candidate| File.file?(candidate) }
    next unless target&.end_with?('.html')

    target_html = File.binread(target).force_encoding(Encoding::UTF_8)
    escaped_fragment = Regexp.escape(fragment)
    next if target_html.match?(/\b(?:id|name)\s*=\s*(?:["']#{escaped_fragment}["']|#{escaped_fragment}(?=[\s>]))/i)

    errors << "#{relative}: missing anchor ##{fragment} in #{internal_path}"
  end
end

Dir.glob(File.join(PUBLIC_ROOT, '**', '*.css')).sort.each do |path|
  relative = path.delete_prefix("#{PUBLIC_ROOT}/")
  css = File.binread(path).force_encoding(Encoding::UTF_8)
  css.scan(/\burl\(\s*["']?([^)'"\s]+)["']?\s*\)/i).flatten.each do |reference|
    internal_path = internal_reference(reference, path)
    next if internal_path.nil?

    if internal_path == :invalid
      errors << "#{relative}: invalid URL #{reference.inspect}"
    elsif !target_exists?(internal_path)
      errors << "#{relative}: missing internal target #{internal_path.inspect} (from #{reference.inspect})"
    end
  end
end

SECTIONS.each do |section, config|
  current_root = File.join(SITE_ROOT, 'content', section)
  current_pages = Dir.glob(File.join(current_root, '*', 'index.md')).sort

  public_section_root = File.join(PUBLIC_ROOT, config[:public])
  rendered_pages = html_paths.select do |path|
    path.start_with?("#{public_section_root}/") && File.binread(path).include?(config[:marker])
  end
  errors << "#{section}: expected #{current_pages.length} rendered detail pages, found #{rendered_pages.length}" unless rendered_pages.length == current_pages.length
  rendered_pages.each do |path|
    html = File.binread(path).force_encoding(Encoding::UTF_8)
    unless html.match?(/\bdata-pagefind-body\b/)
      errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: detail page is excluded from the search index"
    end

    begin
      expected_json_ld_type = { 'publications' => 'Article', 'events' => 'Event', 'blog' => 'BlogPosting' }.fetch(section)
      types = json_ld_types(json_ld_documents(html))
      unless types.include?(expected_json_ld_type)
        errors << "#{path.delete_prefix("#{PUBLIC_ROOT}/")}: JSON-LD types #{types.inspect} do not include #{expected_json_ld_type.inspect}"
      end
    rescue JSON::ParserError
      # The general per-page check reports the malformed document.
    end
  end

  rendered_titles = rendered_pages.to_h do |path|
    html = File.binread(path).force_encoding(Encoding::UTF_8)
    heading = html[/<h1\b[^>]*>(.*?)<\/h1>/mi, 1].to_s
    [path, html_text(heading)]
  end
  source_title_counts = current_pages.each_with_object(Hash.new(0)) do |source_path, counts|
    data, = load_page(source_path)
    counts[normalized(data['title'])] += 1
  end
  rendered_title_counts = rendered_titles.values.each_with_object(Hash.new(0)) { |title, counts| counts[title] += 1 }
  source_title_counts.each do |title, expected_count|
    rendered_count = rendered_title_counts.fetch(title, 0)
    next if rendered_count == expected_count

    errors << "#{section}: title #{title.inspect} rendered #{rendered_count} time(s), expected #{expected_count}"
  end


  current_pages.each do |source_path|
    data, body = load_page(source_path)
    title = normalized(data['title'])
    candidates = rendered_titles.select { |_path, rendered_title| rendered_title == title }.keys
    expected_excerpts = [
      significant_excerpt(body),
      significant_excerpt(data['abstract']),
      significant_excerpt(data['summary'])
    ]
    if section == 'publications'
      expected_excerpts << significant_excerpt(data.dig('publication', 'name'))
    elsif section == 'events'
      expected_excerpts << significant_excerpt(data['event_name'])
      expected_excerpts << significant_excerpt(data['location'])
    end
    expected_excerpts.compact!
    next if expected_excerpts.empty?

    complete_candidate = candidates.any? do |candidate|
      rendered_html = File.binread(candidate).force_encoding(Encoding::UTF_8)
      rendered_text = html_text(rendered_html)
      rendered_source = CGI.unescapeHTML(rendered_html).gsub(/\s+/, ' ')
      expected_excerpts.all? do |excerpt|
        rendered_text.include?(excerpt) || rendered_source.include?(excerpt)
      end
    end
    next if complete_candidate

    errors << "#{source_path.delete_prefix("#{SITE_ROOT}/")}: substantive content is missing from its rendered detail page"
  end
end

home_html = File.join(PUBLIC_ROOT, 'index.html')
if File.file?(home_html) && !File.binread(home_html).match?(/\bdata-pagefind-body\b/)
  errors << 'index.html: homepage is excluded from the search index'
end

SECTIONS.each do |section, config|
  relative_path = File.join(config[:archive], 'index.html')
  expected_items = Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length
  path = File.join(PUBLIC_ROOT, relative_path)
  unless File.file?(path)
    errors << "missing archive page #{relative_path}"
    next
  end

  html = File.binread(path).force_encoding(Encoding::UTF_8)
  errors << "#{relative_path}: wrong archive template" unless html.include?(config[:archive_marker])
  rendered_items = html.scan(config[:item_marker]).length
  errors << "#{relative_path}: rendered #{rendered_items} items, expected #{expected_items}" unless rendered_items == expected_items
end

%w[
  media/CVs/Curriculum_Vitae_EN.pdf
  media/CVs/Curriculum_Vitae_IT.pdf
].each do |relative_path|
  absolute_path = File.join(PUBLIC_ROOT, relative_path)
  errors << "missing downloadable file #{relative_path}" unless File.file?(absolute_path) && File.size(absolute_path).positive?
end

rss_path = File.join(PUBLIC_ROOT, 'index.xml')
if File.file?(rss_path)
  begin
    rss = REXML::Document.new(File.read(rss_path))
    rss_title = rss.elements['rss/channel/title']&.text.to_s.strip
    rss_items = rss.get_elements('rss/channel/item')
    errors << 'index.xml: RSS channel title is missing' if rss_title.empty?
    errors << "index.xml: RSS contains #{rss_items.length} items, expected 58" unless rss_items.length == 58
    errors << 'index.xml: legacy HugoBlox generator is still present' if File.read(rss_path).include?('HugoBlox')
  rescue REXML::ParseException => e
    errors << "index.xml: invalid RSS XML (#{e.message})"
  end
else
  errors << 'missing root RSS feed index.xml'
end

sitemap_path = File.join(PUBLIC_ROOT, 'sitemap.xml')
if File.file?(sitemap_path)
  begin
    sitemap_source = File.read(sitemap_path)
    REXML::Document.new(sitemap_source)
    sitemap_urls = sitemap_source.scan(/<url>/).length
    errors << "sitemap.xml: contains #{sitemap_urls} URLs, expected 259" unless sitemap_urls == 259
  rescue REXML::ParseException => e
    errors << "sitemap.xml: invalid XML (#{e.message})"
  end
else
  errors << 'missing sitemap.xml'
end

robots_path = File.join(PUBLIC_ROOT, 'robots.txt')
if File.file?(robots_path)
  robots = File.read(robots_path)
  errors << 'robots.txt: missing production sitemap URL' unless robots.include?('Sitemap: https://michaelsoprano.com/sitemap.xml')
else
  errors << 'missing robots.txt'
end

pagefind_entry_path = File.join(PUBLIC_ROOT, 'pagefind', 'pagefind-entry.json')
if File.file?(pagefind_entry_path)
  begin
    pagefind_entry = JSON.parse(File.read(pagefind_entry_path))
    indexed_pages = pagefind_entry.fetch('languages', {}).values.sum { |language| language.fetch('page_count', 0).to_i }
    expected_indexed_pages = SECTIONS.keys.sum do |section|
      Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length
    end + 2 # Homepage and privacy page.
    errors << "search index contains #{indexed_pages} pages, expected #{expected_indexed_pages}" unless indexed_pages == expected_indexed_pages
  rescue JSON::ParserError => e
    errors << "invalid Pagefind index metadata: #{e.message}"
  end
end

errors.uniq!
warnings.uniq!

puts "Generated site audited: #{html_paths.length} HTML pages, #{asset_paths.length} files, #{referenced_internal_paths.length} unique internal targets."
puts "Source content audited: #{SECTIONS.keys.map { |section| "#{Dir.glob(File.join(SITE_ROOT, 'content', section, '*', 'index.md')).length} #{section}" }.join(', ')}."
warnings.each { |warning| warn "WARNING: #{warning}" }

if errors.empty?
  puts "Build audit passed#{warnings.empty? ? '' : " with #{warnings.length} warning(s)"}."
else
  errors.each { |error| warn "ERROR: #{error}" }
  warn "Build audit failed with #{errors.length} error(s)."
  exit 1
end
