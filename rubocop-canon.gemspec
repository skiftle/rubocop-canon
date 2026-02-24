# frozen_string_literal: true

require_relative 'lib/rubocop/canon/version'

Gem::Specification.new do |s|
  s.name     = 'rubocop-canon'
  s.version  = RuboCop::Canon::VERSION
  s.authors  = ['skiftle']
  s.summary  = 'Deterministic RuboCop cops for canonical Ruby form'
  s.homepage = 'https://github.com/skiftle/rubocop-canon'
  s.license  = 'MIT'
  s.required_ruby_version = '>= 3.2'

  s.add_dependency 'lint_roller', '~> 1.1'
  s.add_dependency 'rubocop', '>= 1.75.0', '< 2.0'

  s.files = Dir['config/**/*', 'lib/**/*', 'LICENSE.txt', 'README.md']
  s.metadata = {
    'homepage_uri'          => s.homepage,
    'source_code_uri'       => 'https://github.com/skiftle/rubocop-canon',
    'rubygems_mfa_required' => 'true',
  }
end
