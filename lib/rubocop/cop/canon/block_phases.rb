# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces the phase structure of a block body.
      #
      # A body checked by this cop ends in a *trailing phase*: the run of
      # statements that call one of `TrailingMethods`. Exactly one blank line
      # opens that run, no blank line splits it, and the statements before it
      # form at most `MaxPhases` - 1 further phases.
      #
      # `Blocks` names the methods whose blocks are checked and
      # `TrailingMethods` the calls that make up the trailing phase, matched
      # against the leftmost call in a chain. Both are empty by default, so
      # the cop does nothing until it is configured.
      #
      # A body carrying more phases than `MaxPhases` allows keeps the last
      # separator before the trailing phase and loses the earlier ones —
      # everything ahead of the last leading statement is one phase.
      #
      # @example Blocks: ['step'], TrailingMethods: ['report']
      #   # bad — no blank line opens the trailing phase
      #   step 'totals the order' do
      #     order = build_order
      #     report order.total
      #   end
      #
      #   # bad — a blank line splits the trailing phase
      #   step 'totals the order' do
      #     order = build_order
      #
      #     report order.total
      #
      #     report order.currency
      #   end
      #
      #   # good
      #   step 'totals the order' do
      #     order = build_order
      #
      #     report order.total
      #     report order.currency
      #   end
      class BlockPhases < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line inside the trailing phase.'
        MSG_MISSING = 'Add a blank line before the trailing phase.'
        MSG_TOO_MANY_PHASES = 'Use at most %<max_phases>d phases in a block body.'

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
            next if comments_between?(previous, following)
            next if blank_lines_between(previous, following) != 1

            register_extra_blank_line(previous, MSG_EXTRA)
          end
        end

        def check_leading_phases(statements, trailing_start)
          return if trailing_start.zero?

          check_separator(statements[trailing_start - 1], statements[trailing_start])
          check_phase_count(statements[..(trailing_start - 1)])
        end

        def check_separator(previous, following)
          return if comments_between?(previous, following)
          return if blank_lines_between(previous, following) == 1

          register_missing_blank_line(previous, following, MSG_MISSING)
        end

        def check_phase_count(statements)
          separators = leading_separators(statements)
          return if separators.size < max_phases - 1

          surplus = separators[0..-(max_phases - 1)]

          surplus.each do |previous|
            register_extra_blank_line(previous, format(MSG_TOO_MANY_PHASES, max_phases:))
          end
        end

        def leading_separators(statements)
          statements.each_cons(2).filter_map do |previous, following|
            next if comments_between?(previous, following)

            previous if blank_lines_between(previous, following) == 1
          end
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

        def max_phases
          cop_config['MaxPhases']
        end
      end
    end
  end
end
