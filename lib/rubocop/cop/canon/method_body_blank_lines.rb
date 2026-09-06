# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces blank lines around a method body's standalone calls and
      # nowhere else.
      #
      # `SeparatedMethods` names the calls that stand on their own —
      # `authorize!`, `expose`, `mail`. Each takes exactly one blank line
      # between it and any statement next to it. Every other pair of
      # statements takes none, because a blank line there marks a step that
      # wants a name: extract a method instead.
      #
      # The list is empty by default, so the cop only removes until it is
      # configured.
      #
      # The position after a guard clause belongs to
      # `Layout/EmptyLineAfterGuardClause`, so this cop leaves it alone.
      #
      # An entry matches a method name anywhere in the call chain. Write it
      # dotted — `errors.add` — to match a receiver and method together, so
      # `coverage_request.errors.add(...)` matches and a bare `add` does not.
      #
      # @example SeparatedMethods: ['authorize!', 'expose']
      #   # bad
      #   def index
      #     authorize!
      #     shift = find_shift
      #     employees = Employee.for_shift(shift)
      #     expose employees
      #   end
      #
      #   # good
      #   def index
      #     authorize!
      #
      #     shift = find_shift
      #     employees = Employee.for_shift(shift)
      #
      #     expose employees
      #   end
      #
      #   # good — no standalone call, so no blank line
      #   def reset
      #     Current.session = nil
      #     Current.account = nil
      #   end
      #
      #   # good — the guard clause owns its own blank line
      #   def total
      #     items = order.items
      #     return 0 if items.empty?
      #
      #     items.sum(&:amount)
      #   end
      class MethodBodyBlankLines < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line inside the method body.'
        MSG_MISSING = 'Add a blank line around the standalone call.'
        JUMP_METHODS = %i[raise fail throw].freeze

        def on_def(node)
          check_method_body(node)
        end

        def on_defs(node)
          check_method_body(node)
        end

        private

        def check_method_body(node)
          statements = body_statements(node)
          return if statements.size < 2

          statements.each_cons(2) do |previous, following|
            next if guard?(previous)

            check_gap(previous, following, expected_blank_lines(previous, following))
          end
        end

        def check_gap(previous, following, expected)
          return if comments_between?(previous, following)

          blank_lines = blank_lines_between(previous, following)
          return if blank_lines == expected
          return if blank_lines > 1

          return register_extra_blank_line(previous, MSG_EXTRA) if expected.zero?

          register_missing_blank_line(previous, following, MSG_MISSING)
        end

        def expected_blank_lines(previous, following)
          return 1 if separated?(previous)
          return 1 if separated?(following)

          0
        end

        def separated?(node)
          chain = call_chain(node)
          return false if chain.empty?

          separated_methods.any? { |name| matches_chain?(chain, name) }
        end

        def matches_chain?(chain, name)
          return chain.include?(name) unless name.include?('.')

          chain.each_cons(2).any? { |pair| pair.join('.') == name }
        end

        def guard?(node)
          return true if jump?(node)
          return false unless node.if_type?
          return false unless node.modifier_form?
          return true if jump?(node.if_branch)

          jump?(node.else_branch)
        end

        def jump?(node)
          return false if node.nil?
          return true if node.return_type?
          return true if node.break_type?
          return true if node.next_type?

          node.send_type? && JUMP_METHODS.include?(node.method_name)
        end

        def separated_methods
          @separated_methods ||= Array(cop_config['SeparatedMethods']).map(&:to_s)
        end
      end
    end
  end
end
