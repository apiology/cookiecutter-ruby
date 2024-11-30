# frozen_string_literal: true

require 'overcommit'
require 'overcommit/hook/pre_commit/base'

# @!override Overcommit::Hook::Base#execute
#   @return [Overcommit::Subprocess::Result]

module Overcommit
  module Hook
    module PreCommit
      # Runs `solargraph typecheck` against any modified Ruby files.
      class SolargraphTypecheck < Base
        # @return [Array<String>]
        def run
          errors = []

          generate_errors_for_files(errors, *applicable_files)

          # output message to stderr
          errors
        end

        private

        # @param stderr [String]
        #
        # @return [Array<String>]
        def remove_harmless_glitches(stderr)
          stderr.split("\n").reject do |line|
            line.include?('[WARN]') ||
              line.include?('warning: parser/current is loading') ||
              line.include?('Please see https://github.com/whitequark')
          end
        end

        # @param errors [Array<String>]
        # @param file [String]
        # @return [void]
        def generate_errors_for_files(errors, *files)
          result = execute(['bundle', 'exec', 'solargraph', 'typecheck', '--level', 'strong', *files])
          return if result.success?

          stderr = remove_harmless_glitches(result.stderr)
          raise result.stderr unless stderr.empty?

          # @type [String]
          stdout = result.stdout

          stdout.split("\n").each do |error|
            error = parse_error(error)
            errors << error unless error.nil?
          end
        end

        # @param error [String]
        # @return [Overcommit::Hook::Message, nil]
        def parse_error(error)
          # Parse the result for the line number
          # @type [MatchData]
          match = error.match(/^(.+?):(\d+)/)
          return nil unless match

          # @!override MatchData.captures
          #   @return [Array]
          # @sg-ignore
          file_path, lineno = match.captures
          message = error.sub("#{file_path}:#{lineno} - ",
                              "#{file_path}:#{lineno}: ")
          # Emit the errors in the specified format
          Overcommit::Hook::Message.new(:error, file_path, lineno.to_i, message)
        end
      end
    end
  end
end
