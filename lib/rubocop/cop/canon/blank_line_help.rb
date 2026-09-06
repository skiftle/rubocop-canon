# frozen_string_literal: true

module RuboCop
  module Cop
    module Canon
      # Shared mechanics for the cops that decide where a blank line belongs.
      #
      # A cop mixing this in supplies the decision — how many blank lines a
      # pair of statements takes — and leaves the counting, the comment guard,
      # the source ranges and the corrections here.
      module BlankLineHelp
        include RangeHelp

        BLOCK_TYPES = %i[block numblock].freeze

        private

        def body_statements(node)
          body = node.body
          return [] if body.nil?
          return body.children if body.begin_type?

          [body]
        end

        def blank_lines_between(previous, following)
          following.first_line - previous.last_line - 1
        end

        def comments_between?(previous, following)
          processed_source.comments.any? do |comment|
            comment.loc.line >= previous.last_line && comment.loc.line < following.first_line
          end
        end

        def register_extra_blank_line(previous, message)
          add_offense(blank_line_range(previous), message:) do |corrector|
            corrector.remove(newline_range(previous))
          end
        end

        def register_missing_blank_line(previous, following, message)
          add_offense(first_line_range(following), message:) do |corrector|
            corrector.insert_after(line_range(previous.last_line), "\n")
          end
        end

        def call_chain(node)
          chain = []
          current = unwrap_block(node)

          while current.respond_to?(:send_type?) && current.send_type?
            chain.unshift(current.method_name.to_s)
            current = unwrap_block(current.receiver)
          end

          chain
        end

        def unwrap_block(node)
          return if node.nil?
          return node.send_node if BLOCK_TYPES.include?(node.type)

          node
        end

        def line_range(line)
          processed_source.buffer.line_range(line)
        end

        def blank_line_range(previous)
          line_range(previous.last_line + 1)
        end

        def newline_range(previous)
          range_between(line_range(previous.last_line).end_pos, line_range(previous.last_line + 1).end_pos)
        end

        def first_line_range(node)
          line_end = line_range(node.first_line).end_pos

          range_between(node.source_range.begin_pos, [node.source_range.end_pos, line_end].min)
        end
      end
    end
  end
end
