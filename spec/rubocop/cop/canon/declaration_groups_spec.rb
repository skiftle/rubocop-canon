# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::DeclarationGroups do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new('Canon/DeclarationGroups' => { 'GroupedMethods' => grouped_methods }) }
  let(:grouped_methods) { [%w[belongs_to has_many has_one], %w[validate validates], %w[attribute], %w[scope]] }

  it 'registers an offense for a missing blank line between groups' do
    expect_offense(<<~RUBY)
      class Shift
        belongs_to :site
        validates :starts_at, presence: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line between declaration groups.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Shift
        belongs_to :site

        validates :starts_at, presence: true
      end
    RUBY
  end

  it 'registers an offense for a blank line inside a group' do
    expect_offense(<<~RUBY)
      class Shift
        belongs_to :service

      ^{} Remove the blank line between declarations of the same group.
        belongs_to :site
      end
    RUBY

    expect_correction(<<~RUBY)
      class Shift
        belongs_to :service
        belongs_to :site
      end
    RUBY
  end

  it 'does not register an offense for a multiline call in the same group' do
    expect_no_offenses(<<~RUBY)
      class Shift
        scope :published, -> { where.not(published_at: nil) }
        scope :overlapping,
              lambda { |from, to|
                overlaps(:starts_at, :ends_at, from:, to:)
              }
      end
    RUBY
  end

  it 'does not register an offense between two constants' do
    expect_no_offenses(<<~RUBY)
      class Shift
        AND = :AND
        OR = :OR

        EQUALITY = %i[eq].freeze
        COMPARISON = %i[gt lt].freeze
      end
    RUBY
  end

  it 'registers an offense for a DSL block without a blank line before it' do
    expect_offense(<<~RUBY)
      class ShiftRepresentation
        type_name :shift
        with_options filterable: true do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line between declaration groups.
          attribute :id
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class ShiftRepresentation
        type_name :shift

        with_options filterable: true do
          attribute :id
        end
      end
    RUBY
  end

  it 'registers an offense inside a DSL block' do
    expect_offense(<<~RUBY)
      class ShiftRepresentation
        with_options filterable: true do
          attribute :id

      ^{} Remove the blank line between declarations of the same group.
          attribute :starts_at
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class ShiftRepresentation
        with_options filterable: true do
          attribute :id
          attribute :starts_at
        end
      end
    RUBY
  end

  it 'registers an offense for a missing blank line before a method' do
    expect_offense(<<~RUBY)
      class Shift
        belongs_to :site
        def publish
        ^^^^^^^^^^^ Add a blank line between declaration groups.
          true
        end
      end
    RUBY
  end

  context 'with GroupedMethods' do
    let(:grouped_methods) { [%w[belongs_to has_many has_one]] }

    it 'treats the listed methods as one group' do
      expect_no_offenses(<<~RUBY)
        class Shift
          belongs_to :site
          has_many :shift_assignments, dependent: :destroy

          validates :starts_at, presence: true
        end
      RUBY
    end

    it 'registers an offense for a blank line inside the merged group' do
      expect_offense(<<~RUBY)
        class Shift
          belongs_to :site

        ^{} Remove the blank line between declarations of the same group.
          has_many :shift_assignments, dependent: :destroy
        end
      RUBY
    end
  end

  it 'does not register an offense for a canonical class body' do
    expect_no_offenses(<<~RUBY)
      class Shift
        include Publishable

        belongs_to :service
        belongs_to :site

        validates :starts_at, presence: true

        scope :published, -> { where.not(published_at: nil) }

        def publish
          true
        end

        def unpublish
          true
        end
      end
    RUBY
  end

  it 'does not register an offense around an access modifier' do
    expect_no_offenses(<<~RUBY)
      class Shift
        belongs_to :site

        private

        def publish
          true
        end
      end
    RUBY
  end

  it 'does not register an offense for method names the config does not list' do
    expect_no_offenses(<<~RUBY)
      class Filtering < Capability::Base
        capability_name :filtering
        request_transformer RequestTransformer
        api_builder APIBuilder
        operation Operation
      end
    RUBY
  end

  it 'does not register an offense between a listed and an unlisted name' do
    expect_no_offenses(<<~RUBY)
      class Shift < ApplicationRecord
        include Publishable
        belongs_to :site
      end
    RUBY
  end

  it 'does not register an offense for a body holding non-declarations' do
    expect_no_offenses(<<~RUBY)
      class Shift
        result = compute
        belongs_to :site
      end
    RUBY
  end

  it 'does not register an offense for a lambda body' do
    expect_no_offenses(<<~RUBY)
      class Shift
        scope :overlapping,
              lambda { |from, to|
                normalized = normalize(from, to)
                overlaps(normalized)
              }
      end
    RUBY
  end

  it 'does not register an offense when a comment sits between declarations' do
    expect_no_offenses(<<~RUBY)
      class Shift
        has_many :shifts

        # kept
        has_many :sites
      end
    RUBY
  end

  it 'does not register an offense for a trailing comment on the previous line' do
    expect_no_offenses(<<~RUBY)
      class Shift
        has_many :shifts # kept

        has_many :sites
      end
    RUBY
  end

  it 'does not register an offense for a single declaration' do
    expect_no_offenses(<<~RUBY)
      class Shift
        belongs_to :site
      end
    RUBY
  end
end
