require_relative '../../../spec_helper'
require_lib 'reek/cli/command/todo_list_command'
require_lib 'reek/cli/options'
require_lib 'reek/configuration/app_configuration'

RSpec.describe Reek::CLI::Command::TodoListCommand do
  let(:nil_check) { build :smell_detector, smell_type: :NilCheck }
  let(:nested_iterators) { build :smell_detector, smell_type: :NestedIterators }

  describe '#execute' do
    let(:options) { Reek::CLI::Options.new [] }
    let(:configuration) { instance_double 'Reek::Configuration::AppConfiguration' }
    let(:sources) { [source_file] }

    let(:command) do
      described_class.new(options: options,
                          sources: sources,
                          configuration: configuration)
    end

    before do
      allow(File).to receive(:write).with(described_class::DEFAULT_FILE_NAME, String)
    end

    context 'when smells are found' do
      let(:source_file) { SMELLY_FILE }

      it 'shows a proper message' do
        expected = "\n'.reek.yml' generated! You can now use this as a starting point for your configuration.\n"
        expect { command.execute }.to output(expected).to_stdout
      end

      it 'returns a success code' do
        result = Reek::CLI::Silencer.silently { command.execute }
        expect(result).to eq(Reek::CLI::Status::DEFAULT_SUCCESS_EXIT_CODE)
      end

      it 'writes a todo file with exclusions for each smell' do
        Reek::CLI::Silencer.silently { command.execute }
        expected_yaml = {
          Reek::Configuration::AppConfiguration::DETECTORS_KEY =>
          { 'UncommunicativeMethodName' => { 'exclude' => ['Smelly#x'] },
            'UncommunicativeVariableName' => { 'exclude' => ['Smelly#x'] } }
        }.to_yaml
        expect(File).to have_received(:write).with(described_class::DEFAULT_FILE_NAME, expected_yaml)
      end
    end

    context 'when no smells re found' do
      let(:source_file) { CLEAN_FILE }

      it 'shows a proper message' do
        expected = "\n'.reek.yml' not generated because there were no smells found!\n"
        expect { command.execute }.to output(expected).to_stdout
      end

      it 'returns a success code' do
        result = Reek::CLI::Silencer.silently { command.execute }
        expect(result).to eq Reek::CLI::Status::DEFAULT_SUCCESS_EXIT_CODE
      end

      it 'does not write a todo file' do
        Reek::CLI::Silencer.silently { command.execute }
        expect(File).not_to have_received(:write)
      end
    end
  end
end
