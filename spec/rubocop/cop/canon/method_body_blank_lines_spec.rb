# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::Canon::MethodBodyBlankLines do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new('Canon/MethodBodyBlankLines' => { 'SeparatedMethods' => %w[authorize! errors.add expose mail] })
  end

  it 'registers an offense for a result without a blank line before it' do
    expect_offense(<<~RUBY)
      def dispatch(reset)
        @user = reset.user
        @url = reset_url(reset.token)
        mail(to: @user.email)
        ^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the standalone call.
      end
    RUBY

    expect_correction(<<~RUBY)
      def dispatch(reset)
        @user = reset.user
        @url = reset_url(reset.token)

        mail(to: @user.email)
      end
    RUBY
  end

  it 'registers an offense on both sides of the standalone calls' do
    expect_offense(<<~RUBY)
      def index
        authorize!
        employees = Model.for_shift(shift)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the standalone call.
        expose({ employees: })
        ^^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the standalone call.
      end
    RUBY

    expect_correction(<<~RUBY)
      def index
        authorize!

        employees = Model.for_shift(shift)

        expose({ employees: })
      end
    RUBY
  end

  it 'registers an offense for a receiver call named with a dot' do
    expect_offense(<<~RUBY)
      def perform
        record.touch
        record.errors.add(:shift, :required)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the standalone call.
      end
    RUBY

    expect_correction(<<~RUBY)
      def perform
        record.touch

        record.errors.add(:shift, :required)
      end
    RUBY
  end

  it 'registers an offense for a method call result without a blank line' do
    expect_offense(<<~RUBY)
      def destroy
        authorize!
        with_event(site_requirement).trash
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the standalone call.
        expose site_requirement
        ^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the standalone call.
      end
    RUBY

    expect_correction(<<~RUBY)
      def destroy
        authorize!

        with_event(site_requirement).trash

        expose site_requirement
      end
    RUBY
  end

  it 'registers an offense for a blank line before a statement that is not a result' do
    expect_offense(<<~RUBY)
      def reset
        Current.session = nil

      ^{} Remove the blank line inside the method body.
        Current.account = nil
      end
    RUBY

    expect_correction(<<~RUBY)
      def reset
        Current.session = nil
        Current.account = nil
      end
    RUBY
  end

  it 'registers an offense for a blank line in the middle of a body' do
    expect_offense(<<~RUBY)
      def total
        items = order.items

      ^{} Remove the blank line inside the method body.
        taxed = apply_tax(items)

        expose taxed
      end
    RUBY

    expect_correction(<<~RUBY)
      def total
        items = order.items
        taxed = apply_tax(items)

        expose taxed
      end
    RUBY
  end

  it 'registers an offense in a class method body' do
    expect_offense(<<~RUBY)
      def self.dispatch(reset)
        user = reset.user
        mail(to: user.email)
        ^^^^^^^^^^^^^^^^^^^^ Add a blank line around the standalone call.
      end
    RUBY
  end

  it 'does not register an offense for a result opened by a blank line' do
    expect_no_offenses(<<~RUBY)
      def dispatch(reset)
        @user = reset.user
        @url = reset_url(reset.token)

        mail(to: @user.email)
      end
    RUBY
  end

  it 'does not register an offense for a plain sequence' do
    expect_no_offenses(<<~RUBY)
      def reset
        Current.session = nil
        Current.membership = nil
        Current.account = nil
      end
    RUBY
  end

  it 'does not register an offense for a final statement that is not a result' do
    expect_no_offenses(<<~RUBY)
      def total
        items = order.items
        items.sum(&:amount)
      end
    RUBY
  end

  context 'without configuration' do
    let(:config) { RuboCop::Config.new('Canon/MethodBodyBlankLines' => {}) }

    it 'removes but never adds' do
      expect_no_offenses(<<~RUBY)
        def destroy
          authorize!
          expose site_requirement
        end
      RUBY
    end
  end

  it 'does not register an offense for the blank line closing the guard section' do
    expect_no_offenses(<<~RUBY)
      def total
        return 0 if order.nil?

        order.items.sum(&:amount)
      end
    RUBY
  end

  it 'registers an offense for a blank line between two guard clauses' do
    expect_offense(<<~RUBY)
      def total
        return 0 if order.nil?

      ^{} Remove the blank line inside the method body.
        return 0 if order.items.empty?

        order.items.sum(&:amount)
      end
    RUBY

    expect_correction(<<~RUBY)
      def total
        return 0 if order.nil?
        return 0 if order.items.empty?

        order.items.sum(&:amount)
      end
    RUBY
  end

  it 'sets a multiline guard clause apart from the guard before it' do
    expect_offense(<<~RUBY)
      def total
        return 0 if order.nil?
        return 0 unless order.valid?(
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the multiline statement.
          strict: true,
        )

        order.items.sum(&:amount)
      end
    RUBY

    expect_correction(<<~RUBY)
      def total
        return 0 if order.nil?

        return 0 unless order.valid?(
          strict: true,
        )

        order.items.sum(&:amount)
      end
    RUBY
  end

  it 'sets a multiline statement apart inside the body' do
    expect_offense(<<~RUBY)
      def dispatch(reset)
        @user = find_user(
          reset.user_id,
        )
        @url = reset_url(reset.token)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add a blank line around the multiline statement.

        mail(to: @user.email)
      end
    RUBY

    expect_correction(<<~RUBY)
      def dispatch(reset)
        @user = find_user(
          reset.user_id,
        )

        @url = reset_url(reset.token)

        mail(to: @user.email)
      end
    RUBY
  end

  it 'leaves the gap between a guard clause and a bare raise to Layout' do
    expect_no_offenses(<<~RUBY)
      def validate_contract
        return unless resource
        return if contract.valid?
        raise ContractError, contract.issues
      end
    RUBY
  end

  it 'does not remove the blank line Layout puts between a guard clause and a bare raise' do
    expect_no_offenses(<<~RUBY)
      def validate_contract
        return unless resource
        return if contract.valid?

        raise ContractError, contract.issues
      end
    RUBY
  end

  it 'does not register an offense for several guards' do
    expect_no_offenses(<<~RUBY)
      def total
        return 0 if order.nil?
        return 0 if order.items.empty?

        order.items.sum(&:amount)
      end
    RUBY
  end

  it 'does not register an offense for a raise guard' do
    expect_no_offenses(<<~RUBY)
      def total
        raise ArgumentError unless order

        order.items.sum(&:amount)
      end
    RUBY
  end

  it 'does not register an offense when a comment sits between statements' do
    expect_no_offenses(<<~RUBY)
      def dispatch(reset)
        @user = reset.user
        # kept
        mail(to: @user.email)
      end
    RUBY
  end

  it 'does not register an offense for a single statement' do
    expect_no_offenses(<<~RUBY)
      def total
        order.items.sum(&:amount)
      end
    RUBY
  end

  it 'does not register an offense for an empty body' do
    expect_no_offenses(<<~RUBY)
      def total
      end
    RUBY
  end
end
