# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces blank lines between declaration groups in a class, module or
      # DSL block body.
      #
      # Two declarations belong to the same group when they call the same
      # method and both fit on one line. A declaration spanning several lines,
      # and any block, is a group of one. Groups are separated by exactly one
      # blank line; declarations inside a group are not separated at all.
      #
      # `GroupedMethods` merges method names that belong to one group.
      #
      # @example
      #   # bad
      #   class Shift < ApplicationRecord
      #     belongs_to :service
      #
      #     belongs_to :site
      #     validates :starts_at, presence: true
      #   end
      #
      #   # good
      #   class Shift < ApplicationRecord
      #     belongs_to :service
      #     belongs_to :site
      #
      #     validates :starts_at, presence: true
      #   end
      #
      # @example GroupedMethods: [[belongs_to, has_many]]
      #   # good
      #   class Shift < ApplicationRecord
      #     belongs_to :site
      #     has_many :shift_assignments, dependent: :destroy
      #
      #     validates :starts_at, presence: true
      #   end
      class DeclarationGroups < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line between declarations of the same group.'
        MSG_MISSING = 'Add a blank line between declaration groups.'
        ACCESS_MODIFIERS = %i[private protected public module_function private_class_method].freeze
        DEFINITION_TYPES = %i[def defs].freeze
        DECLARATION_TYPES = %i[casgn block numblock def defs].freeze

        def on_class(node)
          check_declarations(node)
        end

        def on_module(node)
          check_declarations(node)
        end

        def on_block(node)
          return unless declaration_context?(node)

          check_declarations(node)
        end

        alias on_numblock on_block

        private

        def check_declarations(node)
          statements = body_statements(node)
          return if statements.size < 2
          return unless statements.all? { |statement| declaration?(statement) }

          statements.each_cons(2) do |previous, following|
            next if definitions?(previous, following)
            next if access_modifier?(previous)
            next if access_modifier?(following)

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
          return 0 if group_key(previous) == group_key(following)

          1
        end

        def group_key(node)
          return node.object_id if multiline?(node)
          return :constant if node.casgn_type?
          return node.object_id unless node.send_type?

          grouped_key(node.method_name)
        end

        def grouped_key(method_name)
          name = method_name.to_s
          group_index = grouped_methods.index { |group| group.include?(name) }
          return name if group_index.nil?

          group_index
        end

        def declaration_context?(node)
          enclosing = node.each_ancestor(:def, :defs, :class, :module).first
          return false if enclosing.nil?
          return true if enclosing.class_type?

          enclosing.module_type?
        end

        def declaration?(node)
          return true if DECLARATION_TYPES.include?(node.type)

          node.send_type? && node.receiver.nil?
        end

        def definitions?(previous, following)
          DEFINITION_TYPES.include?(previous.type) && DEFINITION_TYPES.include?(following.type)
        end

        def access_modifier?(node)
          return false unless node.send_type?
          return false unless node.arguments.empty?

          ACCESS_MODIFIERS.include?(node.method_name)
        end

        def multiline?(node)
          node.first_line != node.last_line
        end

        def grouped_methods
          @grouped_methods ||= Array(cop_config['GroupedMethods']).map { |group| Array(group).map(&:to_s) }
        end
      end
    end
  end
end
