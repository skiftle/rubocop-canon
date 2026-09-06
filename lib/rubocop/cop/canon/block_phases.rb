# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces the phase structure of a block body.
      #
      # A body checked by this cop ends in a *trailing phase*: the run of
      # statements that call one of `TrailingMethods`. Exactly one blank line
      # opens that run. Before it come an arrange phase and, when the last
      # leading statement is a call rather than an assignment, an act phase
      # opened by one blank line. Inside a phase no blank line is allowed.
      #
      # An assignment cannot end the act phase. When the last statement before
      # the trailing phase assigns, there is no act: every leading statement
      # belongs to one arrange phase.
      #
      # A statement spanning several lines is always set apart by a blank line
      # on each side, whatever phase it is in.
      #
      # `Blocks` names the methods whose blocks are checked and
      # `TrailingMethods` the calls that make up the trailing phase, matched
      # against the leftmost call in a chain. Both are empty by default, so
      # the cop does nothing until it is configured.
      #
      # @example Blocks: ['step'], TrailingMethods: ['report']
      #   # bad — no blank line opens the trailing phase
      #   step 'totals the order' do
      #     order = build_order
      #     report order.total
      #   end
      #
      #   # bad — an assignment is arrange, not act
      #   step 'totals the order' do
      #     order = build_order
      #
      #     total = order.total
      #
      #     report total
      #   end
      #
      #   # good
      #   step 'totals the order' do
      #     order = build_order
      #     total = order.total
      #
      #     report total
      #   end
      #
      #   # good — the call is the act
      #   step 'totals the order' do
      #     order = build_order
      #
      #     settle(order)
      #
      #     report order.total
      #   end
      class BlockPhases < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line inside the trailing phase.'
        MSG_MISSING = 'Add a blank line before the trailing phase.'
        MSG_ARRANGE_SPLIT = 'Remove the blank line inside the arrange phase.'
        MSG_ACT_UNSEPARATED = 'Add a blank line before the act.'
        MSG_MULTILINE = 'Add a blank line around the multiline statement.'
        ASSIGNMENT_TYPES = %i[lvasgn ivasgn cvasgn gvasgn masgn op_asgn or_asgn and_asgn].freeze

        def on_block(node)
          return unless configured_block?(node)

          check_phases(node)
        end

        alias on_numblock on_block

        private

        def check_phases(node)
          statements = body_statements(node)
          return if statements.size < 2

          trailing_start = detect_trailing_start(statements)
          return if trailing_start.nil?

          check_trailing_phase(statements, trailing_start)
          check_leading_phases(statements, trailing_start)
        end

        def check_trailing_phase(statements, trailing_start)
          statements[trailing_start..].each_cons(2) do |previous, following|
            if multiline_pair?(previous, following)
              require_blank_line(previous, following, MSG_MULTILINE)
            else
              forbid_blank_line(previous, following, MSG_EXTRA)
            end
          end
        end

        def check_leading_phases(statements, trailing_start)
          return if trailing_start.zero?

          require_blank_line(statements[trailing_start - 1], statements[trailing_start], MSG_MISSING)
          leading = statements[..(trailing_start - 1)]

          leading.each_cons(2).with_index do |(previous, following), index|
            check_leading_gap(leading, previous, following, index)
          end
        end

        def check_leading_gap(leading, previous, following, index)
          if multiline_pair?(previous, following)
            require_blank_line(previous, following, MSG_MULTILINE)
          elsif assignment?(leading.last)
            forbid_blank_line(previous, following, MSG_ARRANGE_SPLIT)
          elsif index == leading.size - 2
            require_blank_line(previous, following, MSG_ACT_UNSEPARATED)
          else
            forbid_blank_line(previous, following, MSG_ARRANGE_SPLIT)
          end
        end

        def require_blank_line(previous, following, message)
          return if comments_between?(previous, following)
          return unless blank_lines_between(previous, following).zero?

          register_missing_blank_line(previous, following, message)
        end

        def forbid_blank_line(previous, following, message)
          return if comments_between?(previous, following)
          return unless blank_lines_between(previous, following) == 1

          register_extra_blank_line(previous, message)
        end

        def multiline_pair?(previous, following)
          return true if multiline?(previous)

          multiline?(following)
        end

        def assignment?(node)
          ASSIGNMENT_TYPES.include?(node.type)
        end

        def detect_trailing_start(statements)
          trailing_start = nil

          statements.each_with_index.reverse_each do |statement, index|
            break unless trailing?(statement)

            trailing_start = index
          end

          trailing_start
        end

        def configured_block?(node)
          return false unless node.send_node.receiver.nil?

          block_methods.include?(node.method_name.to_s)
        end

        def trailing?(node)
          chain = call_chain(node)
          return false if chain.empty?

          trailing_methods.include?(chain.first)
        end

        def block_methods
          @block_methods ||= Array(cop_config['Blocks']).map(&:to_s)
        end

        def trailing_methods
          @trailing_methods ||= Array(cop_config['TrailingMethods']).map(&:to_s)
        end
      end
    end
  end
end
