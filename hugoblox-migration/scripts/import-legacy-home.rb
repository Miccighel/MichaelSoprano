#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'date'

ROOT = File.expand_path('../..', __dir__)
LEGACY_HOME = File.join(ROOT, 'content', 'home')
TARGET = File.join(ROOT, 'hugoblox-migration', 'content', '_index.md')
AUTHOR = File.join(ROOT, 'content', 'authors', 'admin', '_index.md')
LEGACY_DATA = File.join(ROOT, 'hugoblox-migration', 'data', 'legacy-home.yaml')
LEGACY_TOPICS = [
  ['Amazon Mechanical Turk', 'amazon-mechanical-turk'],
  ['argument type identification', 'argument-type-identification'],
  ['audiovisual deepfakes', 'audiovisual-deepfakes'],
  ['benchmarks', 'benchmarks'],
  ['bias', 'bias'],
  ['crowdsourcing', 'crowdsourcing'],
  ['explainability', 'explainability'],
  ['fact-checking', 'fact-checking'],
  ['HITS', 'hits'],
  ['large language models', 'large-language-models'],
  ['misinformation', 'misinformation'],
  ['Network Analysis', 'network-analysis'],
  ['peer review', 'peer-review'],
  ['public administration', 'public-administration'],
  ['readersourcing', 'readersourcing'],
  ['scholarly publishing', 'scholarly-publishing'],
  ['scoping reviews', 'scoping-reviews'],
  ['Teaching', 'teaching'],
  ['truthfulness', 'truthfulness'],
  ['truthfulness assessment', 'truthfulness-assessment']
].freeze

def parse_page(path)
  source = File.binread(path).force_encoding(Encoding::UTF_8)
  match = source.match(/\A---\r?\n(.*?)\r?\n---\r?\n(.*)\z/m)
  raise "Invalid legacy page: #{path}" unless match

  [YAML.load(match[1]) || {}, match[2].gsub(/\r\n?/, "\n").strip]
end

def display_date(value)
  Date.parse(value.to_s).strftime('%b %Y')
rescue Date::Error
  value.to_s
end

def experience_markdown(entries)
  entries.map do |entry|
    organisation = entry['company_url'] ? "[#{entry['company']}](#{entry['company_url']})" : entry['company']
    period = [display_date(entry['date_start']), entry['date_end'] ? display_date(entry['date_end']) : 'present'].join('–')
    "### #{entry['title']}\n\n**#{organisation}** — #{entry['location']}, #{period}.\n\n#{entry['description'].to_s.strip}"
  end.join("\n\n")
end

def social_markdown
  links = [
    ['Email', 'mailto:michael.soprano@uniud.it'],
    ['ORCID', 'https://orcid.org/0000-0002-7337-7592'],
    ['Google Scholar', 'https://scholar.google.it/citations?user=ocK0qRUAAAAJ&hl=en'],
    ['Semantic Scholar', 'https://www.semanticscholar.org/author/Michael-Soprano/51006308'],
    ['DBLP', 'https://dblp.org/pid/222/1241.html'],
    ['ACM Digital Library', 'https://dl.acm.org/profile/99659280921'],
    ['arXiv', 'https://arxiv.org/a/soprano_m_1'],
    ['OSF', 'https://osf.io/fmx3s/'],
    ['ResearchGate', 'https://www.researchgate.net/profile/Michael-Soprano'],
    ['GitHub', 'https://github.com/Miccighel'],
    ['LinkedIn', 'https://www.linkedin.com/in/michaelsoprano/'],
    ['Goodreads', 'https://www.goodreads.com/user/show/53180193-michael-soprano'],
    ['Last.fm', 'https://www.last.fm/it/user/Miccighel'],
    ['Instagram', 'https://www.instagram.com/miccighel/'],
    ['500px', 'https://500px.com/p/miccighel'],
    ['Flickr', 'https://www.flickr.com/photos/jooforge/'],
    ['Steam', 'https://steamcommunity.com/id/miccighel']
  ]
  links.map { |name, url| "[#{name}](#{url})" }.join(' · ')
end

def topic_slug(topic)
  topic.downcase.gsub(/[^a-z0-9]+/, '-').sub(/\A-/, '').sub(/-\z/, '')
end

def topic_data
  counts = Hash.new(0)
  Dir.glob(File.join(ROOT, 'hugoblox-migration', 'content', '{publications,events,blog}', '**', 'index.md')).each do |path|
    metadata, = parse_page(path)
    Array(metadata['tags']).each { |tag| counts[tag] += 1 }
  end

  LEGACY_TOPICS.map do |name, slug|
    count = counts.sum { |tag, value| topic_slug(tag) == slug ? value : 0 }
    { 'name' => name, 'slug' => slug, 'count' => count }
  end
end

def topics_markdown
  topic_data.map { |topic| "[#{topic['name']}](/tag/#{topic['slug']}/)" }.join(' · ')
end

def normalize_author_body(markdown)
  markdown
    .gsub(/\{\{<\s*icon[^>]*>\}\}\s*/, '')
    .gsub(/\{\{<\s*staticref\s+"([^"]+)"\s+"newtab"\s*>\}\}(.*?)\{\{<\s*\/staticref\s*>\}\}/m) do
      destination = Regexp.last_match(1)
      destination = "/#{destination}" unless destination.match?(%r{\A(?:https?://|/)})
      "[#{Regexp.last_match(2)}](#{destination})"
    end
end

widgets = {}
%w[visits experience metrics academic_activity honors].each do |name|
  widgets[name] = parse_page(File.join(LEGACY_HOME, "#{name}.md"))
end
author_meta, author_body = parse_page(AUTHOR)

education = author_meta.dig('education', 'courses').map do |course|
  "- **#{course['course']}** — #{course['institution']} (#{course['year']})"
end.join("\n")
interests = author_meta['interests'].map { |interest| "- #{interest}" }.join("\n")
contact_text = <<~MARKDOWN.strip
  [michael.soprano@uniud.it](mailto:michael.soprano@uniud.it)

  Department of Mathematics, Computer Science and Physics (DMIF), University of Udine — Via delle Scienze 206, 33100 Udine, Italy.

  <form action="https://formspree.io/f/mjvpnjeb" method="POST">
    <p><label>Your email<br><input type="email" name="email" required></label></p>
    <p><label>Message<br><textarea name="message" rows="6" required></textarea></label></p>
    <button type="submit">Send message</button>
  </form>
MARKDOWN

sections = [
  {
    'block' => 'resume-biography', 'id' => 'about',
    'content' => { 'username' => 'michael-soprano', 'button' => { 'text' => 'Download CV', 'url' => '/media/CVs/Curriculum_Vitae_EN.pdf' } },
    'design' => { 'avatar' => { 'size' => 'large', 'shape' => 'circle' } }
  },
  { 'block' => 'markdown', 'id' => 'profiles', 'content' => { 'title' => 'Profiles', 'text' => social_markdown } },
  { 'block' => 'markdown', 'id' => 'interests', 'content' => { 'title' => 'Interests', 'text' => interests } },
  { 'block' => 'markdown', 'id' => 'education', 'content' => { 'title' => 'Education', 'text' => education } },
  { 'block' => 'markdown', 'id' => 'visits', 'content' => { 'title' => widgets['visits'][0]['title'], 'text' => experience_markdown(widgets['visits'][0]['experience']) } },
  { 'block' => 'markdown', 'id' => 'experience', 'content' => { 'title' => widgets['experience'][0]['title'], 'text' => experience_markdown(widgets['experience'][0]['experience']) } },
  { 'block' => 'markdown', 'id' => 'metrics', 'content' => { 'title' => widgets['metrics'][0]['title'], 'text' => widgets['metrics'][1] } },
  { 'block' => 'collection', 'id' => 'publications', 'content' => { 'title' => 'Publications', 'filters' => { 'folders' => ['publications'] } }, 'design' => { 'view' => 'citation' } },
  { 'block' => 'collection', 'id' => 'presentations', 'content' => { 'title' => 'Presentations', 'filters' => { 'folders' => ['events'] } }, 'design' => { 'view' => 'card' } },
  { 'block' => 'markdown', 'id' => 'academic_activity', 'content' => { 'title' => widgets['academic_activity'][0]['title'], 'text' => widgets['academic_activity'][1] } },
  { 'block' => 'collection', 'id' => 'teaching', 'content' => { 'title' => 'Teaching', 'filters' => { 'folders' => ['blog'] } }, 'design' => { 'view' => 'card' } },
  { 'block' => 'markdown', 'id' => 'honors', 'content' => { 'title' => widgets['honors'][0]['title'], 'text' => widgets['honors'][1] } },
  { 'block' => 'markdown', 'id' => 'tags', 'content' => { 'title' => 'Topics', 'text' => topics_markdown } },
  { 'block' => 'markdown', 'id' => 'contact', 'content' => { 'title' => 'Contact', 'text' => contact_text } }
]

document = { 'title' => '', 'date' => '2026-08-01', 'type' => 'landing', 'sections' => sections }
File.write(TARGET, "#{YAML.dump(document)}---\n")

legacy_data = {
  'author' => {
    'title' => author_meta['title'],
    'role' => author_meta['role'],
    'organizations' => author_meta['organizations'],
    'interests' => author_meta['interests'],
    'education' => author_meta.dig('education', 'courses'),
    'social' => author_meta['social'],
    'bio' => normalize_author_body(author_body)
  },
  'visits' => widgets['visits'][0]['experience'],
  'experience' => widgets['experience'][0]['experience'],
  'topics' => topic_data
}
File.write(LEGACY_DATA, YAML.dump(legacy_data))
