# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::KeywordShorthand do
  subject(:cop) { described_class.new }

  it 'registers an offense for keyword with matching local variable' do
    expect_offense(<<~RUBY)
      name = 'test'
      foo(name: name)
          ^^^^^^^^^^ Use Ruby 3 keyword shorthand `name:` instead of `name: name`.
    RUBY

    expect_correction(<<~RUBY)
      name = 'test'
      foo(name:)
    RUBY
  end

  it 'registers an offense in a hash literal' do
    expect_offense(<<~RUBY)
      name = 'test'
      { name: name }
        ^^^^^^^^^^ Use Ruby 3 keyword shorthand `name:` instead of `name: name`.
    RUBY

    expect_correction(<<~RUBY)
      name = 'test'
      { name: }
    RUBY
  end

  it 'registers an offense for multiple matching keywords' do
    expect_offense(<<~RUBY)
      name = 'test'
      age = 25
      foo(name: name, age: age)
          ^^^^^^^^^^ Use Ruby 3 keyword shorthand `name:` instead of `name: name`.
                      ^^^^^^^^ Use Ruby 3 keyword shorthand `age:` instead of `age: age`.
    RUBY

    expect_correction(<<~RUBY)
      name = 'test'
      age = 25
      foo(name:, age:)
    RUBY
  end

  it 'does not register an offense for already shorthand' do
    expect_no_offenses(<<~RUBY)
      name = 'test'
      foo(name:)
    RUBY
  end

  it 'does not register an offense when key and value differ' do
    expect_no_offenses(<<~RUBY)
      foo(name: other_name)
    RUBY
  end

  it 'does not register an offense for non-symbol keys' do
    expect_no_offenses(<<~RUBY)
      { 'name' => name }
    RUBY
  end

  it 'does not register an offense when value is not a local variable' do
    expect_no_offenses(<<~RUBY)
      foo(name: @name)
    RUBY
  end

  it 'does not register an offense for last kwarg before modifier if' do
    expect_no_offenses(<<~RUBY)
      name = 'test'
      foo(name: name) if condition
    RUBY
  end

  it 'does not register an offense for last kwarg before block' do
    expect_no_offenses(<<~RUBY)
      name = 'test'
      foo(name: name) do
        something
      end
    RUBY
  end

  it 'does not register an offense when comment on same line' do
    expect_no_offenses(<<~RUBY)
      name = 'test'
      foo(name: name) # important comment
    RUBY
  end

  it 'corrects non-last kwarg before modifier if' do
    expect_offense(<<~RUBY)
      name = 'test'
      foo(name: name, other: 1) if condition
          ^^^^^^^^^^ Use Ruby 3 keyword shorthand `name:` instead of `name: name`.
    RUBY

    expect_correction(<<~RUBY)
      name = 'test'
      foo(name:, other: 1) if condition
    RUBY
  end
end
