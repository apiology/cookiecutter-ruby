# typed: strict
# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# @!parse
#   module Asana
#     class Client
#       # @return [Asana::ProxiedResourceClasses::Tag]
#       def tags; end
#       # @return [Asana::ProxiedResourceClasses::Task]
#       def tasks; end
#       # @return [Asana::ProxiedResourceClasses::Workspace]
#       def workspaces; end
#       # @return [Asana::ProxiedResourceClasses::Section]
#       def sections; end
#       # @return [Asana::ProxiedResourceClasses::Project]
#       def projects; end
#       # @return [Asana::ProxiedResourceClasses::UserTaskList]
#       def user_task_lists; end
#       # @return [Asana::ProxiedResourceClasses::Portfolio]
#       def portfolios; end
#       # @return [Asana::ProxiedResourceClasses::User]
#       def users; end
#       # @return [Asana::ProxiedResourceClasses::CustomField]
#       def custom_fields; end
#       # @return [Asana::ProxiedResourceClasses::Webhook]
#       def webhooks; end
#
#       # Performs a GET request against an arbitrary Asana URL. Allows for
#       # the user to interact with the API in ways that haven't been
#       # reflected/foreseen in this library.
#       #
#       # @param url [String] the URL to GET
#       # @param args [Object] the request I/O options
#       # @return [Asana::HttpClient::Response]
#       def get(url, **args); end
#     end
#     module Resources
#       # https://developers.asana.com/reference/gettask
#       class Task
#         # @return [String]
#         def resource_subtype; end
#         # @return [Boolean,nil]
#         def is_rendered_as_separator; end
#         # @return [String,nil]
#         def due_at; end
#         # @return [String,nil]
#         def due_on; end
#         # @return [String,nil]
#         def name; end
#         # @return [Hash<String, String>, nil]
#         def assignee; end
#         # @return [String, nil]
#         def html_notes; end
#         # @return [Array<Hash{String => Hash{String => String}}>]
#         def memberships; end
#         # @return [Hash{String => String}, Asana::Resources::Section, nil] if it
#         #   is asked for as part of the initial task request,
#         #   you'll get a hash, otherwise you'll get a resource object
#         def assignee_section; end
#         class << self
#           # @param client [Asana::Client]
#           # @param assignee [String]
#           # @param workspace [String]
#           # @param name [String]
#           # @return [Asana::Resources::Task]
#           def create(client, assignee:, workspace:, name:); end
#         end
#       end
#       class Section
#         # @return [String,nil]
#         def name; end
#       end
#       class Project
#         # @return [String,nil]
#         def name; end
#         # @return [String,nil]
#         def due_date; end
#       end
#       class Portfolio
#         # @param options [Hash] the request I/O options
#         # @return [Enumerable<Asana::Resources::Project>]
#         def get_items(options = {}); end
#       end
#     end
#     module Errors
#       class NotFound < ::Asana::Errors::APIError; end
#       class InvalidRequest < ::Asana::Errors::APIError; end
#     end
#     module Resources
#       class Workspace
#         # @return [String, nil]
#         def html_notes; end
#         class << self
#           # @param client [Asana::Client]
#           # @param id [String]
#           # @param options [Hash]
#           # @return [Asana::Resources::Workspace]
#           def find_by_id(client, id, options: {}); end
#         end
#       end
#     end
#     module ProxiedResourceClasses
#       class CustomField
#         # Get a workspace's custom fields
#         #
#         # @param workspace_gid [String]  (required) Globally unique identifier for the workspace or organization.
#         # @param options [Hash] the request I/O options
#         #
#         # @return [Enumerable<Asana::Resources::CustomField>]
#         def get_custom_fields_for_workspace(workspace_gid: required("workspace_gid"), options: {}); end
#       end
#       class Tag
#          # Get tags in a workspace
#          #
#          # @param workspace_gid [String]  (required) Globally unique identifier for the workspace or organization.
#          # @param options [Hash] the request I/O options
#          # > offset - [str]  Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.'
#          # > limit - [int]  Results per page. The number of objects to return per page. The value must be between 1 and 100.
#          # > opt_fields - [list[str]]  Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options.
#          # > opt_pretty - [bool]  Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging.
#          # @return [Enumerable<Asana::Resources::Tag>]
#          def get_tags_for_workspace(workspace_gid:, options: {}); end
#       end
#       class Task
#         # Get subtasks from a task
#         #
#         # @param task_gid [String]  (required) The task to operate on.
#         # @param options [Hash] the request I/O options
#         # > offset - [str]  Offset token. An offset to the next page returned by the API. A pagination request will return an offset token, which can be used as an input parameter to the next request. If an offset is not passed in, the API will return the first page of results. 'Note: You can only pass in an offset that was returned to you via a previously paginated request.'
#         # > limit - [int]  Results per page. The number of objects to return per page. The value must be between 1 and 100.
#         # > opt_fields - [list[str]]  Defines fields to return. Some requests return *compact* representations of objects in order to conserve resources and complete the request more efficiently. Other times requests return more information than you may need. This option allows you to list the exact set of fields that the API should be sure to return for the objects. The field names should be provided as paths, described below. The id of included objects will always be returned, regardless of the field options.
#         # > opt_pretty - [bool]  Provides “pretty” output. Provides the response in a “pretty” format. In the case of JSON this means doing proper line breaking and indentation to make it readable. This will take extra time and increase the response size so it is advisable only to use this during debugging.
#         # @return [Enumerable<Asana::Resources::Task>]
#         def get_subtasks_for_task(task_gid: required("task_gid"), options: {}); end
#         # Returns the complete task record for a single task.
#         #
#         # @param id [String] The task to get.
#         # @param options [Hash] the request I/O options.
#         # @return [Asana::Resources::Task]
#         def find_by_id(id, options: {}); end
#         # Returns the compact task records for some filtered set of tasks. Use one
#         # or more of the parameters provided to filter the tasks returned. You must
#         # specify a `project`, `section`, `tag`, or `user_task_list` if you do not
#         # specify `assignee` and `workspace`.
#         #
#         # @param assignee [String] The assignee to filter tasks on.
#         # @param workspace [String] The workspace or organization to filter tasks on.
#         # @param project [String] The project to filter tasks on.
#         # @param section [String] The section to filter tasks on.
#         # @param tag [String] The tag to filter tasks on.
#         # @param user_task_list [String] The user task list to filter tasks on.
#         # @param completed_since [String] Only return tasks that are either incomplete or that have been
#         # completed since this time.
#         #
#         # @param modified_since [String] Only return tasks that have been modified since the given time.
#         #
#         # @param per_page [Integer] the number of records to fetch per page.
#         # @param options [Hash] the request I/O options.
#         # Notes:
#         #
#         # If you specify `assignee`, you must also specify the `workspace` to filter on.
#         #
#         # If you specify `workspace`, you must also specify the `assignee` to filter on.
#         #
#         # Currently, this is only supported in board views.
#         #
#         # A task is considered "modified" if any of its properties change,
#         # or associations between it and other objects are modified (e.g.
#         # a task being added to a project). A task is not considered modified
#         # just because another object it is associated with (e.g. a subtask)
#         # is modified. Actions that count as modifying the task include
#         # assigning, renaming, completing, and adding stories.
#         # @return [Enumerable<Asana::Resources::Task>]
#         def find_all(assignee: nil, workspace: nil, project: nil, section: nil,
#                      tag: nil, user_task_list: nil, completed_since: nil,
#                      modified_since: nil, per_page: 20, options: {}); end
#         # @param assignee [String]
#         # @param project [String]
#         # @param section [Asana::Resources::Section, String]
#         # @param workspace [String]
#         # @param completed_since [Time]
#         # @param per_page [Integer]
#         # @param modified_since [Time]
#         # @param options [Hash] the request I/O options.
#         # @return [Enumerable<Asana::Resources::Task>]
#         def get_tasks(assignee: nil,
#                       project: nil,
#                       section: nil,
#                       workspace: nil,
#                       completed_since: nil,
#                       per_page: 20,
#                       modified_since: nil,
#                       options: {}); end
#       end
#       class Workspace
#         # @return [Enumerable<Asana::Resources::Workspace>]
#         def find_all; end
#       end
#       class Section
#         # @param project_gid [String]
#         # @param options [Hash]
#         # @return [Enumerable<Asana::Resources::Section>]
#         def get_sections_for_project(project_gid:, options: {}); end
#         # Returns the complete record for a single section.
#         #
#         # @param [String] id - The section to get.
#         # @param options [Hash] - the request I/O options.
#         # @return [Asana::Resources::Section]
#         def find_by_id(id, options: {}); end
#       end
#       class Project
#         # Returns the compact project records for all projects in the workspace.
#         #
#         # @param workspace [String] The workspace or organization to find projects in.
#         # @param is_template [Boolean] **Note: This parameter can only be included if a team is also defined, or the workspace is not an organization**
#         # Filters results to include only template projects.
#         #
#         # @param archived [Boolean] Only return projects whose `archived` field takes on the value of
#         # this parameter.
#         #
#         # @param per_page [Integer] the number of records to fetch per page.
#         # @param options [Hash] the request I/O options.
#         # @return [Enumerable<Asana::Resources::Project>]
#         def find_by_workspace(workspace: required("workspace"), is_template: nil, archived: nil, per_page: 20, options: {}); end
#         # Returns the complete project record for a single project.
#         #
#         # @param id [String] The project to get.
#         # @param options [Hash] the request I/O options.
#         # @return [Asana::Resources::Project]
#         def find_by_id(id, options: {}); end
#       end
#       class UserTaskList
#         # @param user_gid [String]  (required) A string identifying a user. This can either be the string \"me\", an email, or the gid of a user.
#         # @param workspace [String]  (required) The workspace in which to get the user task list.
#         # @param options [Hash] the request I/O options
#         # @return [Asana::Resources::UserTaskList]
#         def get_user_task_list_for_user(user_gid:,
#             workspace: nil, options: {}); end
#       end
#       class Portfolio
#         # Returns a list of the portfolios in compact representation that are owned
#         # by the current API user.
#         #
#         # @param workspace [String] The workspace or organization to filter portfolios on.
#         # @param owner [String] The user who owns the portfolio. Currently, API users can only get a
#         # list of portfolios that they themselves own.
#         #
#         # @param per_page [Integer] the number of records to fetch per page.
#         # @param options [Hash] the request I/O options.
#         #
#         # @return [Enumerable<Asana::Resources::Portfolio>]
#         def find_all(workspace: required("workspace"), owner: required("owner"), per_page: 20, options: {}); end
#         # Returns the complete record for a single portfolio.
#         #
#         # @param id [String] The portfolio to get.
#         # @param options [Hash] the request I/O options.
#
#         # @return [Asana::Resources::Portfolio,nil]
#         def find_by_id(id, options: {}); end
#         # Get portfolio items
#         #
#         # @param portfolio_gid [String]  (required) Globally unique identifier for the portfolio.
#         # @param options [Hash] the request I/O options
#         #
#         # @return [Enumerable<Asana::Resources::Project>]
#         def get_items_for_portfolio(portfolio_gid: required("portfolio_gid"), options: {}); end
#       end
#       class User
#         # Returns the full user record for the currently authenticated user.
#         #
#         # @param options [Hash] the request I/O options.
#         #
#         # @return [Asana::Resources::User]
#         def me(options: {}); end
#       end
#       class Webhook
#         # Returns the compact representation of all webhooks your app has
#         # registered for the authenticated user in the given workspace.
#         #
#         # @param workspace [String] The workspace to query for webhooks in.
#         # @param resource [String] Only return webhooks for the given resource.
#         # @param per_page [Integer] the number of records to fetch per page.
#         # @param options [Hash] the request I/O options.
#         # @return [Array<Asana::Resources::Webhook>]
#         def get_all(workspace: required("workspace"), resource: nil, per_page: 20, options: {})
#         end
#         # @param options [Hash] the request I/O options
#         # @param data [Hash] the attributes to POST
#         # @return [Asana::Resources::Webhook]
#         def create_webhook(options: {}, **data)
#         end
#       end
#     end
#   end
#   module Asana
#     include ::Asana::Resources
#   end
# rubocop:enable Layout/LineLength
