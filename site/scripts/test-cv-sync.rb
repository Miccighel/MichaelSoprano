#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'digest'
require 'open3'
require 'rbconfig'

class CvSyncTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir('cv-sync-test-')
    FileUtils.mkdir_p(File.join(@root, 'scripts'))
    FileUtils.cp(File.join(__dir__, 'check-cv-sync.rb'), File.join(@root, 'scripts/check-cv-sync.rb'))
    files = %w[data/bibliometrics.json static/media/CVs/Curriculum_Vitae_EN.pdf static/media/CVs/Curriculum_Vitae_IT.pdf]
    hashes = files.to_h do |path|
      full = File.join(@root, path)
      FileUtils.mkdir_p(File.dirname(full))
      File.write(full, 'fixture')
      [path, Digest::SHA256.file(full).hexdigest]
    end
    File.write(File.join(@root, 'data/cv-sync.json'), JSON.generate('schema' => 1, 'files' => hashes))
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def run_check
    Open3.capture3(RbConfig.ruby, File.join(@root, 'scripts/check-cv-sync.rb')).last.success?
  end

  def test_matching_export_passes
    assert run_check
  end

  def test_changed_pdf_fails
    File.write(File.join(@root, 'static/media/CVs/Curriculum_Vitae_EN.pdf'), 'changed')
    refute run_check
  end

  def test_changed_metrics_fail
    File.write(File.join(@root, 'data/bibliometrics.json'), 'changed')
    refute run_check
  end

  def test_missing_file_fails
    File.delete(File.join(@root, 'static/media/CVs/Curriculum_Vitae_IT.pdf'))
    refute run_check
  end
end
