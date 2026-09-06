# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::BlockPhases do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      'Canon/BlockPhases' => {
        'Blocks' => %w[step],
        'TrailingMethods' => %w[report confirm],
      },
    )
  end

  it 'registers an offense for a missing blank line before the trailing phase' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order
        report order.total
        ^^^^^^^^^^^^^^^^^^ Add a blank line before the trailing phase.
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order

        report order.total
      end
    RUBY
  end

  it 'registers an offense for a blank line inside the trailing phase' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

        report order.total

      ^{} Remove the blank line inside the trailing phase.
        report order.currency
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order

        report order.total
        report order.currency
      end
    RUBY
  end

  it 'registers an offense for a blank line inside the arrange phase before the act' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

      ^{} Remove the blank line inside the arrange phase.
        add_item(order)

        settle(order)

        report order.total
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order
        add_item(order)

        settle(order)

        report order.total
      end
    RUBY
  end

  it 'keeps only the last separator when several phases are surplus' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

      ^{} Remove the blank line inside the arrange phase.
        add_item(order)

      ^{} Remove the blank line inside the arrange phase.
        apply_tax(order)

        settle(order)

        report order.total
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order
        add_item(order)
        apply_tax(order)

        settle(order)

        report order.total
      end
    RUBY
  end

  it 'keeps only the separator before the act' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

      ^{} Remove the blank line inside the arrange phase.
        add_item(order)

      ^{} Remove the blank line inside the arrange phase.
        apply_tax(order)

        settle(order)

        report order.total
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order
        add_item(order)
        apply_tax(order)

        settle(order)

        report order.total
      end
    RUBY
  end

  it 'registers an offense for a blank line before an assignment that ends the arrange phase' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

      ^{} Remove the blank line inside the arrange phase.
        total = order.total

        report total
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order
        total = order.total

        report total
      end
    RUBY
  end

  it 'collapses every separator when the arrange phase ends in an assignment' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

      ^{} Remove the blank line inside the arrange phase.
        add_item(order)

      ^{} Remove the blank line inside the arrange phase.
        total = order.total

        report total
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order
        add_item(order)
        total = order.total

        report total
      end
    RUBY
  end

  it 'does not register an offense for an act phase ending in a call' do
    expect_no_offenses(<<~RUBY)
      step 'totals the order' do
        order = build_order

        settle(order)

        report order.total
      end
    RUBY
  end

  it 'registers an offense for a multiline statement without blank lines around it' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order
        total = order.total(
        ^^^^^^^^^^^^^^^^^^^^ Add a blank line around the multiline statement.
          currency: :sek,
        )
        report total
        ^^^^^^^^^^^^ Add a blank line before the trailing phase.
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order

        total = order.total(
          currency: :sek,
        )

        report total
      end
    RUBY
  end

  it 'registers an offense for a multiline call inside the trailing phase without blank lines around it' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        report order.total
        report(
        ^^^^^^^ Add a blank line around the multiline statement.
          order.currency,
        )
        report order.status
        ^^^^^^^^^^^^^^^^^^^ Add a blank line around the multiline statement.
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        report order.total

        report(
          order.currency,
        )

        report order.status
      end
    RUBY
  end

  it 'does not register an offense for a multiline statement already set apart' do
    expect_no_offenses(<<~RUBY)
      step 'totals the order' do
        order = build_order

        total = order.total(
          currency: :sek,
        )

        report total
      end
    RUBY
  end

  it 'recognises a chained call as trailing' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order
        report(order).to_stdout
        ^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line before the trailing phase.
      end
    RUBY
  end

  it 'recognises a call taking a block as trailing' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order
        report { order.total }.to_stdout
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line before the trailing phase.
      end
    RUBY
  end

  it 'does not register an offense for two phases' do
    expect_no_offenses(<<~RUBY)
      step 'totals the order' do
        order = build_order

        report order.total
      end
    RUBY
  end

  it 'does not register an offense for three phases' do
    expect_no_offenses(<<~RUBY)
      step 'totals the order' do
        order = build_order

        settle(order)

        report order.total
        confirm order.currency
      end
    RUBY
  end

  it 'does not register an offense for a body that only reports' do
    expect_no_offenses(<<~RUBY)
      step 'totals the order' do
        report build_order.total
        confirm build_order.currency
      end
    RUBY
  end

  it 'does not register an offense for a body without a trailing call' do
    expect_no_offenses(<<~RUBY)
      step 'totals the order' do
        order = build_order

        settle(order)
      end
    RUBY
  end

  it 'does not register an offense when a comment sits before the trailing phase' do
    expect_no_offenses(<<~RUBY)
      step 'totals the order' do
        order = build_order
        # kept
        report order.total
      end
    RUBY
  end

  it 'does not register an offense for an unlisted block' do
    expect_no_offenses(<<~RUBY)
      stage 'totals the order' do
        order = build_order
        report order.total
      end
    RUBY
  end

  it 'does not register an offense for a receiver call' do
    expect_no_offenses(<<~RUBY)
      runner.step 'totals the order' do
        order = build_order
        report order.total
      end
    RUBY
  end

  context 'without configuration' do
    let(:config) { RuboCop::Config.new('Canon/BlockPhases' => {}) }

    it 'does nothing' do
      expect_no_offenses(<<~RUBY)
        step 'totals the order' do
          order = build_order
          report order.total
        end
      RUBY
    end
  end
end
