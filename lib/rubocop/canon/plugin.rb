# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Canon
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-canon',
          version: VERSION,
          homepage: 'https://github.com/skiftle/rubocop-canon',
          description: 'Deterministic RuboCop cops for canonical Ruby form.',
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join('../../..')
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: project_root.join('config', 'default.yml'),
        )
      end
    end
  end
end
