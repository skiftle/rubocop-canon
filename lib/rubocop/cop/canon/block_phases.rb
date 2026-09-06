# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces the two-phase structure of a block body.
      #
      # A body checked by this cop has two phases. The *trailing phase* begins
      # at the first call to one of `TrailingMethods` and runs to the end of
      # the body, whatever else it holds. Everything before it is the *setup*.
      # Exactly one blank line separates the two, and no blank line appears
      # inside either — except around a statement spanning several lines,
      # which is always set apart.
      #
      # There is no act phase and nothing is left to the author: where a blank
      # line goes follows from the statements alone.
      #
      # `Blocks` names the methods whose blocks are checked and
      # `TrailingMethods` the calls that make up the trailing phase, matched
      # against the leftmost call in a chain. Both are empty by default, so
      # the cop does nothing until it is configured.
      #
      # @example Blocks: ['step'], TrailingMethods: ['report']
      #   # bad
      #   step 'totals the order' do
      #     order = build_order
      #
      #     settle(order)
      #     report order.total
      #   end
      #
      #   # good
      #   step 'totals the order' do
      #     order = build_order
      #     settle(order)
      #
      #     report order.total
      #   end
      #
      #   # good — everything from the first trailing call on is one phase
      #   step 'lists the orders' do
      #     fetch_orders
      #
      #     report status
      #     body = parse_body
      #     reload
      #     report body
      #   end
      class BlockPhases < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line inside the trailing phase.'
        MSG_MISSING = 'Add a blank line before the trailing phase.'
        MSG_SETUP_SPLIT = 'Remove the blank line inside the setup.'

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

          check_trailing_phase(statements[trailing_start..])
          check_setup(statements[...trailing_start], statements[trailing_start])
        end

        def check_trailing_phase(statements)
          statements.each_cons(2) do |previous, following|
            check_gap(previous, following, MSG_EXTRA)
          end
        end

        def check_setup(statements, first_trailing)
          return if statements.empty?

          require_blank_line(statements.last, first_trailing, MSG_MISSING)
          statements.each_cons(2) do |previous, following|
            check_gap(previous, following, MSG_SETUP_SPLIT)
          end
        end

        def check_gap(previous, following, extra_message)
          if multiline_pair?(previous, following)
            require_blank_line(previous, following, MSG_MULTILINE)
          else
            forbid_blank_line(previous, following, extra_message)
          end
        end

        def detect_trailing_start(statements)
          statements.index { |statement| trailing?(statement) }
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
