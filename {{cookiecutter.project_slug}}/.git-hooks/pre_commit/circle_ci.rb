# typed: true
# frozen_string_literal: true

require 'overcommit'
require 'overcommit/hook/pre_commit/base'

module Overcommit
  module Hook
    module PreCommit
      # CircleCI plugin for Overcommit to validate config file (.circleci/config.yml)
      class CircleCi < Base
        # @return [Symbol, Array<Symbol, String>]
        def run
          result = execute(command)
          # @sg-ignore
          return :pass if result.success?

          # @sg-ignore
          if result.success?
            :pass
          else
            # @sg-ignore
            [:fail, result.stderr]
          end
        end
      end
    end
  end
end
