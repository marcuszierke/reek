# frozen_string_literal: true

require_relative 'base_command'
require_relative '../../examiner'
require_relative '../../configuration/app_configuration'
require_relative '../../configuration/configuration_file_finder'

module Reek
  module CLI
    module Command
      #
      # A command to collect smells from a set of sources and writes a configuration
      # file that can serve as a todo list.
      #
      class TodoListCommand < BaseCommand
        DEFAULT_FILE_NAME = Configuration::ConfigurationFileFinder::DEFAULT_FILE_NAME

        def execute
          if smells.empty?
            puts "\n'#{DEFAULT_FILE_NAME}' not generated because "\
                    'there were no smells found!'
          else
            File.write DEFAULT_FILE_NAME,
                       { Configuration::AppConfiguration::DETECTORS_KEY => groups }.to_yaml
            puts "\n'#{DEFAULT_FILE_NAME}' generated! You can now use "\
                    'this as a starting point for your configuration.'
          end
          options.success_exit_code
        end

        private

        def smells
          @smells ||= sources.map do |source|
            Examiner.new(source, filter_by_smells: smell_names)
          end.map(&:smells).flatten
        end

        def groups
          @groups ||=
            begin
              todos = smells.group_by(&:smell_class).map do |smell_class, smells_for_class|
                smell_class.todo_configuration_for(smells_for_class)
              end
              todos.inject(&:merge)
            end
        end
      end
    end
  end
end
