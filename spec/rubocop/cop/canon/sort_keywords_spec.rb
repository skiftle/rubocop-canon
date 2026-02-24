# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::SortKeywords do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      'Canon/SortKeywords' => {
        'Enabled' => true,
        'ShorthandsFirst' => false,
        'Methods' => ['attribute'],
      },
    )
  end

  it 'registers an offense for unsorted keyword arguments' do
    expect_offense(<<~RUBY)
      attribute :name, zebra: true, alpha: false
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sort keyword arguments alphabetically.
    RUBY

    expect_correction(<<~RUBY)
      attribute :name, alpha: false, zebra: true
    RUBY
  end

  it 'does not register an offense for sorted keyword arguments' do
    expect_no_offenses(<<~RUBY)
      attribute :name, alpha: false, zebra: true
    RUBY
  end

  it 'does not register an offense for single keyword argument' do
    expect_no_offenses(<<~RUBY)
      attribute :name, alpha: true
    RUBY
  end

  it 'does not register an offense for non-configured methods' do
    expect_no_offenses(<<~RUBY)
      other_method :name, zebra: true, alpha: false
    RUBY
  end

  it 'does not register an offense for methods with receiver' do
    expect_no_offenses(<<~RUBY)
      obj.attribute :name, zebra: true, alpha: false
    RUBY
  end

  it 'corrects multiline unsorted keyword arguments' do
    expect_offense(<<~RUBY)
      attribute :name,
      ^^^^^^^^^^^^^^^^ Sort keyword arguments alphabetically.
                zebra: true,
                alpha: false
    RUBY

    expect_correction(<<~RUBY)
      attribute :name,
                alpha: false,
                zebra: true
    RUBY
  end

  context 'with ShorthandsFirst enabled' do
    let(:config) do
      RuboCop::Config.new(
        'Canon/SortKeywords' => {
          'Enabled' => true,
          'ShorthandsFirst' => true,
          'Methods' => ['attribute'],
        },
      )
    end

    it 'sorts shorthands before expanded keyword arguments' do
      expect_offense(<<~RUBY)
        name = 'test'
        attribute :foo, z: 1, name:, a: 2
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sort keyword arguments alphabetically.
      RUBY

      expect_correction(<<~RUBY)
        name = 'test'
        attribute :foo, name:, a: 2, z: 1
      RUBY
    end
  end

  context 'with empty Methods list' do
    let(:config) do
      RuboCop::Config.new(
        'Canon/SortKeywords' => {
          'Enabled' => true,
          'ShorthandsFirst' => false,
          'Methods' => [],
        },
      )
    end

    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        attribute :name, zebra: true, alpha: false
      RUBY
    end
  end
end
