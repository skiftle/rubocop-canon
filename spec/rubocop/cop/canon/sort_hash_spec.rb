# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::SortHash do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      'Canon/SortHash' => {
        'Enabled' => true,
        'ShorthandsFirst' => false,
        'ExcludeMethods' => [],
      },
    )
  end

  it 'registers an offense for unsorted hash keys' do
    expect_offense(<<~RUBY)
      {b: 1, a: 2}
      ^^^^^^^^^^^^^ Sort hash keys alphabetically.
    RUBY

    expect_correction(<<~RUBY)
      {a: 2, b: 1}
    RUBY
  end

  it 'does not register an offense for sorted hash keys' do
    expect_no_offenses(<<~RUBY)
      {a: 1, b: 2, c: 3}
    RUBY
  end

  it 'does not register an offense for single-element hash' do
    expect_no_offenses(<<~RUBY)
      {a: 1}
    RUBY
  end

  it 'does not register an offense for non-symbol keys' do
    expect_no_offenses(<<~RUBY)
      {'b' => 1, 'a' => 2}
    RUBY
  end

  it 'does not register an offense for hashes with kwsplat' do
    expect_no_offenses(<<~RUBY)
      {b: 1, **options}
    RUBY
  end

  it 'does not register an offense for duplicate keys' do
    expect_no_offenses(<<~RUBY)
      {a: 1, a: 2}
    RUBY
  end

  it 'corrects multiline unsorted hash' do
    expect_offense(<<~RUBY)
      {
      ^ Sort hash keys alphabetically.
        c: 3,
        a: 1,
        b: 2,
      }
    RUBY

    expect_correction(<<~RUBY)
      {
        a: 1,
        b: 2,
        c: 3,
      }
    RUBY
  end

  it 'preserves spaces in single-line hash with braces' do
    expect_offense(<<~RUBY)
      { b: 1, a: 2 }
      ^^^^^^^^^^^^^^^ Sort hash keys alphabetically.
    RUBY

    expect_correction(<<~RUBY)
      { a: 2, b: 1 }
    RUBY
  end

  context 'with ShorthandsFirst enabled' do
    let(:config) do
      RuboCop::Config.new(
        'Canon/SortHash' => {
          'Enabled' => true,
          'ShorthandsFirst' => true,
          'ExcludeMethods' => [],
        },
      )
    end

    it 'sorts shorthands before expanded pairs' do
      expect_offense(<<~RUBY)
        name = 'test'
        {z: 1, name:, a: 2}
        ^^^^^^^^^^^^^^^^^^^^ Sort hash keys alphabetically.
      RUBY

      expect_correction(<<~RUBY)
        name = 'test'
        {name:, a: 2, z: 1}
      RUBY
    end
  end

  context 'with ExcludeMethods' do
    let(:config) do
      RuboCop::Config.new(
        'Canon/SortHash' => {
          'Enabled' => true,
          'ShorthandsFirst' => false,
          'ExcludeMethods' => ['enum'],
        },
      )
    end

    it 'does not register an offense for excluded methods' do
      expect_no_offenses(<<~RUBY)
        enum(status: {b: 1, a: 2})
      RUBY
    end
  end
end
