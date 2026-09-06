# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces blank lines around a method body's standalone calls and
      # multiline statements, and nowhere else.
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
      # Guard clauses group: two in a row take no blank line between them.
      # The position after the last guard belongs to
      # `Layout/EmptyLineAfterGuardClause`, so this cop leaves it alone — and
      # recognises a guard by that cop's own definition: an `if` whose branch
      # is a single-line `return`, `break`, `next`, `raise` or `fail`. A bare
      # `raise` on its own line is a statement, not a guard.
      #
      # A statement spanning several lines is always set apart by a blank
      # line on each side, guards included.
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
      #   # good — guards group, and the last one owns the blank line after it
      #   def total
      #     return 0 if order.nil?
      #     return 0 if order.items.empty?
      #
      #     order.items.sum(&:amount)
      #   end
      class MethodBodyBlankLines < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line inside the method body.'
        MSG_MISSING = 'Add a blank line around the standalone call.'
        JUMP_METHODS = %i[raise fail].freeze

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
            next if guard_boundary?(previous, following)

            check_gap(previous, following)
          end
        end

        def guard_boundary?(previous, following)
          return false unless guard?(previous)

          !guard?(following)
        end

        def check_gap(previous, following)
          if multiline_pair?(previous, following)
            require_blank_line(previous, following, MSG_MULTILINE)
          elsif separated_pair?(previous, following)
            require_blank_line(previous, following, MSG_MISSING)
          else
            forbid_blank_line(previous, following, MSG_EXTRA)
          end
        end

        def separated_pair?(previous, following)
          return true if separated?(previous)

          separated?(following)
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
          return false unless node.if_type?

          branch = node.if_branch
          return false if branch.nil?
          return true if branch.guard_clause?

          jump?(branch)
        end

        def jump?(node)
          return true if node.return_type?
          return true if node.break_type?
          return true if node.next_type?
          return false unless node.send_type?
          return false unless node.receiver.nil?

          JUMP_METHODS.include?(node.method_name)
        end

        def separated_methods
          @separated_methods ||= Array(cop_config['SeparatedMethods']).map(&:to_s)
        end
      end
    end
  end
end
