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
      # Guard clauses group by what they do: the guards that return sit
      # together, the guards that raise sit together, and one blank line
      # separates the two groups. The position after the last guard belongs
      # to `Layout/EmptyLineAfterGuardClause`, so this cop leaves it alone —
      # and recognises a guard by that cop's own definition: an `if` whose
      # branch is a single-line `return`, `break`, `next`, `raise` or `fail`.
      # A bare `raise` on its own line is a statement, not a guard. A guard
      # whose branch spans several lines is a multiline statement to both
      # cops, so this cop sets it apart.
      #
      # A statement spanning several lines — a heredoc counts — is always set
      # apart by a blank line on each side, guards included.
      #
      # A method that rescues has several bodies: the statements it protects,
      # each `rescue` clause, the `else` and the `ensure`. The rules apply
      # inside each of them.
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
      #
      #   # good — the guards that return and the guard that raises are two groups
      #   def resolve(name)
      #     return nil if name.nil?
      #     return name if name.is_a?(Array)
      #
      #     raise ArgumentError, "#{name} not found" unless enums.key?(name)
      #
      #     enums.fetch(name)
      #   end
      class MethodBodyBlankLines < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line inside the method body.'
        MSG_MISSING = 'Add a blank line around the standalone call.'
        MSG_MIXED_GUARDS = 'Add a blank line between a guard that returns and a guard that raises.'
        CLAUSE_TYPES = %i[ensure rescue resbody].freeze
        JUMP_METHODS = %i[raise fail].freeze

        def on_def(node)
          check_method_body(node)
        end

        def on_defs(node)
          check_method_body(node)
        end

        private

        def check_method_body(node)
          statement_lists(node.body).each { |statements| check_statements(statements) }
        end

        def statement_lists(node)
          return [] if node.nil?
          return [statements(node)] unless CLAUSE_TYPES.include?(node.type)

          clause_bodies(node).flat_map { |body| statement_lists(body) }
        end

        def clause_bodies(node)
          return [node.children.first, node.branch] if node.ensure_type?
          return [node.body] if node.resbody_type?

          [node.body, *node.resbody_branches, node.else_branch]
        end

        def check_statements(statements)
          statements.each_cons(2) do |previous, following|
            next if guard_boundary?(previous, following)

            check_gap(previous, following)
          end
        end

        def guard_boundary?(previous, following)
          return false unless guard?(previous)

          !contains_guard?(following)
        end

        def check_gap(previous, following)
          if multiline_pair?(previous, following)
            require_blank_line(previous, following, MSG_MULTILINE)
          elsif mixed_guards?(previous, following)
            require_blank_line(previous, following, MSG_MIXED_GUARDS)
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

        def mixed_guards?(previous, following)
          return false unless guard?(previous)
          return false unless guard?(following)

          raising_guard?(previous) != raising_guard?(following)
        end

        def guard?(node)
          return false unless node.if_type?

          branch = node.if_branch
          return false if branch.nil?

          branch.guard_clause?
        end

        def contains_guard?(node)
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

        def raising_guard?(node)
          jump = node.if_branch
          jump = jump.rhs if jump.operator_keyword?

          jump.send_type?
        end

        def separated_methods
          @separated_methods ||= Array(cop_config['SeparatedMethods']).map(&:to_s)
        end
      end
    end
  end
end
