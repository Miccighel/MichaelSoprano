#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'minitest/autorun'
require 'tmpdir'
require_relative 'check-cv-pdf-links'

class CvPdfLinksTest < Minitest::Test
  WSDM_SLIDES = 'WSDM-2022_Crowd_Frame-A-Simple-and-Complete-Framework-to-Deploy-Complex-Crowdsourcing-Tasks-Off-the-shelf.pdf'

  def setup
    @public_root = Dir.mktmpdir('cv-pdf-links-')
    FileUtils.mkdir_p(File.join(@public_root, 'media', 'talks'))
    File.write(File.join(@public_root, 'index.html'), 'home')
    File.write(File.join(@public_root, 'media', 'talks', WSDM_SLIDES), 'slides')
  end

  def teardown
    FileUtils.remove_entry(@public_root)
  end

  def output_for(url)
    "Page  Type          URL\n   3  Annotation    #{url}\n"
  end

  def test_exact_site_asset_passes
    assert_empty CvPdfLinks.missing_links(output_for("https://michaelsoprano.com/media/talks/#{WSDM_SLIDES}"), @public_root)
  end

  def test_wrong_case_is_rejected_even_on_case_insensitive_filesystems
    bad_url = "https://michaelsoprano.com/media/talks/#{WSDM_SLIDES.sub('Off-the-shelf', 'Off-the-Shelf')}"
    assert_equal [[3, bad_url]], CvPdfLinks.missing_links(output_for(bad_url), @public_root)
  end

  def test_homepage_passes
    assert_empty CvPdfLinks.missing_links(output_for('https://michaelsoprano.com/'), @public_root)
  end

  def test_external_links_are_not_checked_against_site_files
    assert_empty CvPdfLinks.missing_links(output_for('https://dl.acm.org/doi/abs/10.1145/3488560.3502182'), @public_root)
  end
end
