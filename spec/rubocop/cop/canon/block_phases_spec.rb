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

  it 'registers an offense for a blank line inside the setup' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

      ^{} Remove the blank line inside the setup.
        settle(order)

        report order.total
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order = build_order
        settle(order)

        report order.total
      end
    RUBY
  end

  it 'removes every blank line inside the setup' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order = build_order

      ^{} Remove the blank line inside the setup.
        add_item(order)

      ^{} Remove the blank line inside the setup.
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

  it 'treats an attribute setter like any other setup statement' do
    expect_offense(<<~RUBY)
      step 'totals the order' do
        order.currency = :sek

      ^{} Remove the blank line inside the setup.
        order.total = 100

        report order
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'totals the order' do
        order.currency = :sek
        order.total = 100

        report order
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

  it 'treats everything from the first trailing call on as the trailing phase' do
    expect_no_offenses(<<~RUBY)
      step 'lists the orders' do
        fetch_orders

        report status
        body = parse_body
        reload_orders
        report body
      end
    RUBY
  end

  it 'registers an offense for a blank line around a call inside the trailing phase' do
    expect_offense(<<~RUBY)
      step 'lists the orders' do
        report status
        reload_orders

      ^{} Remove the blank line inside the trailing phase.
        report body
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'lists the orders' do
        report status
        reload_orders
        report body
      end
    RUBY
  end

  it 'registers an offense for blank lines around a wedged assignment' do
    expect_offense(<<~RUBY)
      step 'lists the orders' do
        report status

      ^{} Remove the blank line inside the trailing phase.
        body = parse_body

      ^{} Remove the blank line inside the trailing phase.
        report body
      end
    RUBY

    expect_correction(<<~RUBY)
      step 'lists the orders' do
        report status
        body = parse_body
        report body
      end
    RUBY
  end

  it 'starts the trailing phase at the first trailing call, not at a preceding assignment' do
    expect_offense(<<~RUBY)
      step 'lists the orders' do
        body = parse_body
        report body
        ^^^^^^^^^^^ Add a blank line before the trailing phase.
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

  it 'does not register an offense for a canonical body' do
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
