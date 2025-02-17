# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/localizable_source'

default_platform(:ios)

GLOTPRESS_PROJECT_BASE_URL = 'https://translate.wordpress.com/projects/gravatar/gravatar-ios-sdk/'

SOURCES_TO_LOCALIZE = [
  LocalizableSource.new(
    source_paths: [File.join('Sources', 'GravatarUI')],
    localizations_root: File.join('Sources', 'GravatarUI', 'Resources'),
    gp_project_url: "#{GLOTPRESS_PROJECT_BASE_URL}/gravatarui/"
  ),
  LocalizableSource.new(
    source_paths: [
      File.join('Demo', 'Demo', 'Gravatar-Demo')
    ],
    localizations_root: File.join('Demo', 'Demo', 'Localizations'),
    gp_project_url: nil # We don't perform translations for the Demo project yet
  )
].freeze

# List of locales used for the app strings (GlotPress code => `*.lproj` folder name`)
#
# TODO: Replace with `LocaleHelper` once provided by release toolkit (https://github.com/wordpress-mobile/release-toolkit/pull/296)
GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES = {
  'ar' => 'ar',         # Arabic
  'de' => 'de',         # German
  'es' => 'es',         # Spanish
  'fr' => 'fr',         # French
  'he' => 'he',         # Hebrew
  'id' => 'id',         # Indonesian
  'it' => 'it',         # Italian
  'ja' => 'ja',         # Japanese
  'ko' => 'ko',         # Korean
  'nl' => 'nl',         # Dutch
  'pt-br' => 'pt-BR',   # Portuguese (Brazil)
  'ru' => 'ru',         # Russian
  'sv' => 'sv',         # Swedish
  'tr' => 'tr',         # Turkish
  'zh-cn' => 'zh-Hans', # Chinese (China)
  'zh-tw' => 'zh-Hant'  # Chinese (Taiwan)
}.freeze

#################################################
# Lanes
#################################################

# Lanes related to Localization and GlotPress
#
platform :ios do
  # Download the latest localizations from GlotPress and update the SDK accordingly.
  #
  # @example Running the lane
  #          bundle exec fastlane download_localized_strings skip_commit:true
  #
  desc 'Downloads localized strings (`.strings`) from GlotPress and commits them'
  lane :download_localized_strings do |skip_commit: false|
    paths_to_commit = []

    SOURCES_TO_LOCALIZE.each do |source|
      next if source.gp_project_url.nil?

      check_translation_progress(
        glotpress_url: source.gp_project_url,
        abort_on_violations: false
      )

      ios_download_strings_files_from_glotpress(
        project_url: source.gp_project_url,
        locales: GLOTPRESS_TO_LPROJ_APP_LOCALE_CODES,
        download_dir: source.localizations_root
      )

      ios_lint_localizations(
        input_dir: source.localizations_root
      )

      next if skip_commit

      paths_to_commit << source.localizations_root
    end

    next if skip_commit

    git_add(path: paths_to_commit)
    git_commit(
      path: paths_to_commit,
      message: 'Update localizations',
      allow_nothing_to_commit: true
    )
  end

  # Generates the `.strings` files for the base language by parsing source code (using `genstring`).
  #
  lane :generate_strings do |skip_commit: false|
    paths_to_commit = []

    SOURCES_TO_LOCALIZE.each do |source|
      ios_generate_strings_file_from_code(
        paths: source.source_paths,
        exclude: ['**/SDKLocalizedString.swift'],
        routines: ['SDKLocalizedString'],
        output_dir: source.base_localization_root,
        output_encoding: 'UTF-8'
      )

      next if skip_commit

      paths_to_commit << source.localizations_root
    end

    next if skip_commit

    git_add(path: paths_to_commit)
    git_commit(
      path: paths_to_commit,
      message: 'Update strings in base locale',
      allow_nothing_to_commit: true
    )
  end
end
