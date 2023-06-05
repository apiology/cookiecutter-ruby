# frozen_string_literal: true

require 'overcommit'
require 'overcommit/hook/pre_commit/base'

# Overcommit configuration
module Overcommit
  module Hook
    module PreCommit
      # Runs `punchlist` against any modified Ruby files.
      class Punchlist < Base
        # @param stdout [String]
        # @return [Array<Overcommit::Hook::Message]
        def parse_output(stdout)
          stdout.split("\n").map do |line|
            # @sg-ignore
            file, line_no, _message = line.split(':', 3)
            Overcommit::Hook::Message.new(:error, file, line_no.to_i, line)
          end
        end

        def files_glob
          "{" \
            "#{applicable_files.join(',')}" \
            "}"
        end

        def run
          # @sg-ignore
          # @type [Overcommit::Subprocess::Result]
          result = execute([*command, '-g', files_glob])

          warn result.stderr

          # If the command exited with a non-zero status or produced any output, treat it as a failure
          if result.status.nonzero? || !result.stdout.empty? || !result.stderr.empty?
            # Parse the output to create Message objects
            stdout = result.stdout
            messages = parse_output(stdout)

            return messages
          end

          :pass
        end
      end
    end
  end
end
