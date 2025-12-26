# frozen_string_literal: true

Redmine::Plugin.register :parent_grouping do
  name 'Parent Grouping plugin'
  author 'Softices'
  description 'Grouping and sorting tasks by parent task'
  version '0.0.1'

  settings(
    default: {
      'enabled'   => '1',
      'root_sort' => 'desc', # asc | desc
      'default_grouping' => '0' # 0 = manual, 1 = auto-apply to all projects
    },
    partial: 'settings/parent_grouping'
  )
end

# ------------------------------------------------------------
# Patch IssueQuery early so Group-by dropdown sees parent_id
# ------------------------------------------------------------
require_dependency 'issue_query'
require_relative 'lib/parent_grouping/issue_query_patch'

unless IssueQuery.included_modules.include?(ParentGrouping::IssueQueryPatch)
  IssueQuery.send(:include, ParentGrouping::IssueQueryPatch)
end