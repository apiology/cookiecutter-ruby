# frozen_string_literal: true

require 'overcommit'
require 'overcommit/hook/pre_commit/base'

module Overcommit
  module Hook
    module PreCommit
      # CircleCI plugin for Overcommit to validate config file (.circleci/config.yml)
      class CircleCi < Base
        def run
          result = execute(command)
          return :pass if result.success?

          if result.success?
            :pass
          else
            [:fail, result.stderr]
          end
        end
      end
    end
  end
end
