# frozen_string_literal: true

module ParentGrouping
  module IssueQueryPatch
    def self.included(base)
      base.class_eval do

        # ----------------------------------------------------
        # 1. Make "Parent task" available as a column
        # ----------------------------------------------------
        alias_method :available_columns_without_parent_grouping, :available_columns
        def available_columns
          cols = available_columns_without_parent_grouping

          # Remove any existing parent_id column first
          cols.reject! { |c| c.name == :parent_id }

          cols << QueryColumn.new(
            :parent_id,
            caption: :field_parent_issue,
            sortable: "#{Issue.table_name}.parent_id",
            default_order: 'desc'
          )

          cols
        end

        # ----------------------------------------------------
        # 2. Make "Parent task" groupable
        # ----------------------------------------------------
        alias_method :groupable_columns_without_parent_grouping, :groupable_columns
        def groupable_columns
          cols = groupable_columns_without_parent_grouping

          # Remove any existing parent_id column first
          cols.reject! { |c| c.name == :parent_id }

          cols << QueryColumn.new(
            :parent_id,
            caption: :field_parent_issue,
            groupable: "#{Issue.table_name}.parent_id",
            sortable: "#{Issue.table_name}.parent_id",
            default_order: 'desc'
          )

          cols
        end

        # ----------------------------------------------------
        # 3. KEY FIX: Override group_by_sort_order
        #    This controls HOW GROUPS are ordered
        # ----------------------------------------------------
        alias_method :group_by_sort_order_without_parent_grouping, :group_by_sort_order
        def group_by_sort_order
          # Only apply custom logic when grouping by parent_id
          unless group_by.to_s == 'parent_id'
            return group_by_sort_order_without_parent_grouping
          end

          settings = Setting.plugin_parent_grouping || {}

          # Default: DESC (newest parent tasks first)
          group_order = if settings['root_sort'].to_s.strip.downcase == 'asc'
                          'ASC'
                        else
                          'DESC'
                        end

          # CRITICAL: This makes blank (NULL) groups appear LAST
          # Then orders actual parent groups by parent_id DESC
          [
            Arel.sql("CASE WHEN #{Issue.table_name}.parent_id IS NULL THEN 1 ELSE 0 END ASC"),
            Arel.sql("#{Issue.table_name}.parent_id #{group_order}")
          ]
        end

        # ----------------------------------------------------
        # 4. Override sort_clause for SUBTASK ordering
        #    This controls order WITHIN each group
        # ----------------------------------------------------
        alias_method :sort_clause_without_parent_grouping, :sort_clause
        def sort_clause
          original_clause = sort_clause_without_parent_grouping

          # Only apply when grouping by parent_id
          unless group_by.to_s == 'parent_id'
            return original_clause
          end

          settings = Setting.plugin_parent_grouping || {}

          # Default: DESC (newest subtasks first)
          subtask_order = if settings['subtask_sort'].to_s.strip.downcase == 'asc'
                            'ASC'
                          else
                            'DESC'
                          end

          # Order subtasks by ID within each group
          [Arel.sql("#{Issue.table_name}.id #{subtask_order}")]
        end

        # ----------------------------------------------------
        # 5. Default sort criteria when grouping by parent
        # ----------------------------------------------------
        alias_method :default_sort_criteria_without_parent_grouping, :default_sort_criteria
        def default_sort_criteria
          settings = Setting.plugin_parent_grouping || {}

          unless settings['enabled'] == '1' &&
                 group_by.to_s == 'parent_id' &&
                 sort_criteria.blank?
            return default_sort_criteria_without_parent_grouping
          end

          group_order = settings['root_sort'].to_s.strip.downcase == 'asc' ? 'asc' : 'desc'
          subtask_order = settings['subtask_sort'].to_s.strip.downcase == 'asc' ? 'asc' : 'desc'

          [['parent_id', group_order], ['id', subtask_order]]
        end

        # ----------------------------------------------------
        # 6. Preserve sort after params rebuild
        # ----------------------------------------------------
        alias_method :build_from_params_without_parent_grouping, :build_from_params
        def build_from_params(*args)
          result = build_from_params_without_parent_grouping(*args)

          settings = Setting.plugin_parent_grouping || {}

          if settings['enabled'] == '1' && group_by.to_s == 'parent_id'
            group_order = settings['root_sort'].to_s.strip.downcase == 'asc' ? 'asc' : 'desc'
            subtask_order = settings['subtask_sort'].to_s.strip.downcase == 'asc' ? 'asc' : 'desc'

            self.sort_criteria = [['parent_id', group_order], ['id', subtask_order]]
          end

          result
        end

      end
    end
  end
end