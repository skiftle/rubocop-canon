# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces blank lines between declaration groups in a class, module,
      # singleton class or DSL block body.
      #
      # Every method name is its own group: two declarations calling the same
      # method take no blank line between them, and two calling different
      # methods take exactly one. `GroupedMethods` merges names into one
      # group — `belongs_to` with `has_many`, `validate` with `validates`.
      # Constants are a group of their own, and so are the two Ruby families
      # RuboCop's layout cops already treat as one: `attr`, `attr_accessor`,
      # `attr_reader` and `attr_writer`; `extend`, `include` and `prepend`.
      #
      # A declaration is a call without a receiver or on `self`, or a constant
      # assignment. A declaration spanning several lines, a block and a method
      # definition are each a group of one whatever they call, so they always
      # stand apart from their neighbours. Two definitions in a row belong to
      # `Layout/EmptyLineBetweenDefs` and the lines around an access modifier
      # to `Layout/EmptyLinesAroundAccessModifier`, so this cop leaves those
      # alone. Anything else — an assignment, a conditional — it has no
      # opinion about.
      #
      # A DSL block counts when it has no receiver and is a statement of a
      # class, module or singleton class body, or of such a block: `included
      # do`, `with_options ... do`, `action :index do`. A block passed as an
      # argument — the lambda given to `scope` — is left alone.
      #
      # @example GroupedMethods: [[belongs_to, has_many], [validate, validates]]
      #   # bad
      #   class Shift < ApplicationRecord
      #     belongs_to :site
      #
      #     has_many :shift_assignments, dependent: :destroy
      #     validates :starts_at, presence: true
      #     scope :upcoming, -> { where(starts_at: Time.current..) }
      #
      #     scope :past, -> { where(starts_at: ...Time.current) }
      #   end
      #
      #   # good
      #   class Shift < ApplicationRecord
      #     belongs_to :site
      #     has_many :shift_assignments, dependent: :destroy
      #
      #     validates :starts_at, presence: true
      #
      #     scope :upcoming, -> { where(starts_at: Time.current..) }
      #     scope :past, -> { where(starts_at: ...Time.current) }
      #   end
      class DeclarationGroups < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line between declarations of the same group.'
        MSG_MISSING = 'Add a blank line between declaration groups.'
        ACCESS_MODIFIERS = %i[private protected public module_function private_class_method].freeze
        BODY_TYPES = %i[class module sclass].freeze
        BUILT_IN_GROUPS = [%w[attr attr_accessor attr_reader attr_writer], %w[extend include prepend]].freeze
        DEFINITION_TYPES = %i[def defs].freeze

        def on_class(node)
          check_declarations(node)
        end

        def on_module(node)
          check_declarations(node)
        end

        def on_sclass(node)
          check_declarations(node)
        end

        def on_block(node)
          return unless declaration_block?(node)

          check_declarations(node)
        end

        alias on_numblock on_block

        private

        def check_declarations(node)
          statements = body_statements(node)
          return if statements.size < 2

          statements.each_cons(2) do |previous, following|
            next if definitions?(previous, following)
            next if access_modifier?(previous)
            next if access_modifier?(following)
            next unless grouped?(previous, following)

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

        def grouped?(previous, following)
          return true if standalone?(previous)
          return true if standalone?(following)
          return false if group_key(previous).nil?

          !group_key(following).nil?
        end

        def expected_blank_lines(previous, following)
          return 1 if standalone?(previous)
          return 1 if standalone?(following)
          return 0 if group_key(previous) == group_key(following)

          1
        end

        def standalone?(node)
          return true if BLOCK_TYPES.include?(node.type)
          return true if definition?(node)

          multiline?(node)
        end

        def group_key(node)
          return :constant if node.casgn_type?
          return unless declaration_call?(node)

          name = node.method_name.to_s
          group = groups.find { |members| members.include?(name) }
          group.nil? ? name : group.first
        end

        def declaration_call?(node)
          return false unless node.send_type?
          return true if node.receiver.nil?

          node.receiver.self_type?
        end

        def declaration_block?(node)
          return false unless node.send_node.receiver.nil?

          declaration_body?(node.parent)
        end

        def declaration_body?(node)
          return false if node.nil?
          return declaration_body?(node.parent) if node.begin_type?
          return true if BODY_TYPES.include?(node.type)
          return false unless BLOCK_TYPES.include?(node.type)

          declaration_block?(node)
        end

        def definition?(node)
          return true if DEFINITION_TYPES.include?(node.type)
          return false unless node.send_type?

          node.arguments.any? { |argument| DEFINITION_TYPES.include?(argument.type) }
        end

        def definitions?(previous, following)
          return false unless definition?(previous)

          definition?(following)
        end

        def access_modifier?(node)
          return false unless node.send_type?
          return false unless node.arguments.empty?

          ACCESS_MODIFIERS.include?(node.method_name)
        end

        def groups
          @groups ||= BUILT_IN_GROUPS + Array(cop_config['GroupedMethods']).map { |group| Array(group).map(&:to_s) }
        end
      end
    end
  end
end
