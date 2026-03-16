# frozen_string_literal: true

require_relative 'lib/legion/extensions/enactive_cognition/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-enactive-cognition'
  spec.version       = Legion::Extensions::EnactiveCognition::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Enactive Cognition'
  spec.description   = "Varela's enactivism: cognition through action-perception loops, sensorimotor contingencies, and structural coupling"
  spec.homepage      = 'https://github.com/LegionIO/lex-enactive-cognition'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-enactive-cognition'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-enactive-cognition'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-enactive-cognition'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-enactive-cognition/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-enactive-cognition.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
