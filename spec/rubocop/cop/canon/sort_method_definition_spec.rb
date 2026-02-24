# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::SortMethodDefinition do
  subject(:cop) { described_class.new }

  it 'registers an offense for unsorted keyword arguments in def' do
    expect_offense(<<~RUBY)
      def foo(zebra:, alpha:)
      ^^^ Sort keyword arguments alphabetically.
      end
    RUBY

    expect_correction(<<~RUBY)
      def foo(alpha:, zebra:)
      end
    RUBY
  end

  it 'registers an offense for unsorted keyword arguments in defs' do
    expect_offense(<<~RUBY)
      def self.foo(zebra:, alpha:)
      ^^^ Sort keyword arguments alphabetically.
      end
    RUBY

    expect_correction(<<~RUBY)
      def self.foo(alpha:, zebra:)
      end
    RUBY
  end

  it 'does not register an offense for sorted keyword arguments' do
    expect_no_offenses(<<~RUBY)
      def foo(alpha:, zebra:)
      end
    RUBY
  end

  it 'does not register an offense for single keyword argument' do
    expect_no_offenses(<<~RUBY)
      def foo(alpha:)
      end
    RUBY
  end

  it 'does not register an offense for no keyword arguments' do
    expect_no_offenses(<<~RUBY)
      def foo(bar, baz)
      end
    RUBY
  end

  it 'does not register an offense for kwrestarg' do
    expect_no_offenses(<<~RUBY)
      def foo(zebra:, alpha:, **rest)
      end
    RUBY
  end

  it 'does not register an offense for multiline keyword arguments' do
    expect_no_offenses(<<~RUBY)
      def foo(zebra:,
              alpha:)
      end
    RUBY
  end

  it 'preserves keyword arguments with defaults' do
    expect_offense(<<~RUBY)
      def foo(zebra: 'z', alpha: 'a')
      ^^^ Sort keyword arguments alphabetically.
      end
    RUBY

    expect_correction(<<~RUBY)
      def foo(alpha: 'a', zebra: 'z')
      end
    RUBY
  end

  it 'preserves positional arguments before keyword arguments' do
    expect_offense(<<~RUBY)
      def foo(bar, zebra:, alpha:)
      ^^^ Sort keyword arguments alphabetically.
      end
    RUBY

    expect_correction(<<~RUBY)
      def foo(bar, alpha:, zebra:)
      end
    RUBY
  end

  it 'sorts three or more keyword arguments' do
    expect_offense(<<~RUBY)
      def foo(charlie:, alpha:, bravo:)
      ^^^ Sort keyword arguments alphabetically.
      end
    RUBY

    expect_correction(<<~RUBY)
      def foo(alpha:, bravo:, charlie:)
      end
    RUBY
  end
end
