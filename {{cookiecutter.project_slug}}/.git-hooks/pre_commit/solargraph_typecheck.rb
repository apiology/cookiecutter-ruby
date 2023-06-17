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

          applicable_files.each do |file|
            generate_errors_for_file(file, errors)
          end

          # output message to stderr
          errors
        end

        private

        # @param file [String]
        # @param errors [Array<String>]
        # @return [void]
        def generate_errors_for_file(file, errors)
          result = execute(['bundle', 'exec', 'solargraph', 'typecheck', '--level', 'strong', file])
          return if result.success?

          # @type [String]
          stdout = result.stdout

          stdout.split("\n").each do |error|
            error = parse_error(file, error)
            errors << error unless error.nil?
          end
        end

        # @param file [String]
        # @param error [String]
        # @return [Overcommit::Hook::Message, nil]
        def parse_error(file, error)
          # Parse the result for the line number                # @type [MatchData]
          match = error.match(/^(.+?):(\d+)/)
          return nil unless match

          # @!override MatchData.captures
          #   @return [Array]
          # @sg-ignore
          file_path, lineno = match.captures
          message = error.sub("#{file_path}:#{lineno} - ",
                              "#{file_path}:#{lineno}: ")
          # Emit the errors in the specified format
          Overcommit::Hook::Message.new(:error, file, lineno.to_i, message)
        end
      end
    end
  end
end
