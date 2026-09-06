# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Enforces blank lines between declaration groups in a class, module or
      # DSL block body.
      #
      # `GroupedMethods` is the whole specification: two declarations calling
      # methods listed in the same group take no blank line between them, and
      # two calling methods listed in different groups take exactly one. The
      # cop says nothing about a method name it has not been given, so a DSL
      # it does not know stays as its author wrote it.
      #
      # A declaration spanning several lines, and any block, is a group of one
      # whatever it calls, so it always stands apart from its neighbours.
      # Everything else the cop has not been told about — an unlisted method
      # name on one line, a constant — it leaves alone.
      #
      # @example GroupedMethods: [[belongs_to, has_many], [validate, validates]]
      #   # bad
      #   class Shift < ApplicationRecord
      #     belongs_to :site
      #
      #     has_many :shift_assignments, dependent: :destroy
      #     validates :starts_at, presence: true
      #   end
      #
      #   # good
      #   class Shift < ApplicationRecord
      #     belongs_to :site
      #     has_many :shift_assignments, dependent: :destroy
      #
      #     validates :starts_at, presence: true
      #   end
      #
      #   # good — neither name is listed, so the cop leaves the body alone
      #   class Filtering < Capability::Base
      #     request_transformer RequestTransformer
      #     api_builder APIBuilder
      #   end
      class DeclarationGroups < Base
        extend AutoCorrector
        include BlankLineHelp

        MSG_EXTRA = 'Remove the blank line between declarations of the same group.'
        MSG_MISSING = 'Add a blank line between declaration groups.'
        ACCESS_MODIFIERS = %i[private protected public module_function private_class_method].freeze
        DEFINITION_TYPES = %i[def defs].freeze
        BLOCK_TYPES = %i[block numblock].freeze
        STANDALONE_TYPES = %i[block numblock def defs].freeze

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
          return true if STANDALONE_TYPES.include?(node.type)

          multiline?(node)
        end

        def multiline?(node)
          node.first_line != node.last_line
        end

        def group_key(node)
          return unless node.send_type?

          grouped_methods.index { |group| group.include?(node.method_name.to_s) }
        end

        def declaration_context?(node)
          enclosing = node.each_ancestor(:def, :defs, :class, :module).first
          return false if enclosing.nil?
          return true if enclosing.class_type?

          enclosing.module_type?
        end

        def declaration?(node)
          return true if node.casgn_type?
          return true if DEFINITION_TYPES.include?(node.type)
          return node.send_node.receiver.nil? if BLOCK_TYPES.include?(node.type)

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

        def grouped_methods
          @grouped_methods ||= Array(cop_config['GroupedMethods']).map { |group| Array(group).map(&:to_s) }
        end
      end
    end
  end
end
