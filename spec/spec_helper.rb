# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require 'rubocop-canon'

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    metadata[:ruby32] = true
  end
end
