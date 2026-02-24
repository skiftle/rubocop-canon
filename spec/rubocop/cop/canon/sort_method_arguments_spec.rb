# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::SortMethodArguments do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      'Canon/SortMethodArguments' => {
        'Enabled' => true,
        'Methods' => %w[attr_reader delegate],
      },
    )
  end

  it 'registers an offense for unsorted symbol arguments' do
    expect_offense(<<~RUBY)
      attr_reader :zebra, :alpha
      ^^^^^^^^^^^ Sort symbol arguments alphabetically.
    RUBY

    expect_correction(<<~RUBY)
      attr_reader :alpha, :zebra
    RUBY
  end

  it 'does not register an offense for sorted symbol arguments' do
    expect_no_offenses(<<~RUBY)
      attr_reader :alpha, :zebra
    RUBY
  end

  it 'does not register an offense for single symbol argument' do
    expect_no_offenses(<<~RUBY)
      attr_reader :name
    RUBY
  end

  it 'does not register an offense for non-configured methods' do
    expect_no_offenses(<<~RUBY)
      other_method :zebra, :alpha
    RUBY
  end

  it 'does not register an offense for methods with receiver' do
    expect_no_offenses(<<~RUBY)
      obj.attr_reader :zebra, :alpha
    RUBY
  end

  it 'corrects multiline unsorted symbol arguments' do
    expect_offense(<<~RUBY)
      attr_reader :zebra,
      ^^^^^^^^^^^ Sort symbol arguments alphabetically.
                  :alpha
    RUBY

    expect_correction(<<~RUBY)
      attr_reader :alpha,
                  :zebra
    RUBY
  end

  it 'preserves trailing keyword arguments' do
    expect_offense(<<~RUBY)
      delegate :zebra, :alpha, to: :target
      ^^^^^^^^ Sort symbol arguments alphabetically.
    RUBY

    expect_correction(<<~RUBY)
      delegate :alpha, :zebra, to: :target
    RUBY
  end

  it 'sorts three or more arguments' do
    expect_offense(<<~RUBY)
      attr_reader :charlie, :alpha, :bravo
      ^^^^^^^^^^^ Sort symbol arguments alphabetically.
    RUBY

    expect_correction(<<~RUBY)
      attr_reader :alpha, :bravo, :charlie
    RUBY
  end

  context 'with empty Methods list' do
    let(:config) do
      RuboCop::Config.new(
        'Canon/SortMethodArguments' => {
          'Enabled' => true,
          'Methods' => [],
        },
      )
    end

    it 'does not register any offenses' do
      expect_no_offenses(<<~RUBY)
        attr_reader :zebra, :alpha
      RUBY
    end
  end
end
