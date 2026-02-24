# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/expect_offense'
require 'rubocop-canon'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
end
