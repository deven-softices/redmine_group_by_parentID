# frozen_string_literal: true

module ParentGrouping
  # Custom value class for parent_id display
  # Acts as an integer for aggregation but displays as formatted string
  class ParentIdValue
    attr_reader :id

    def initialize(parent_id)
      @id = parent_id
      @parent = parent_id.present? ? Issue.find_by(id: parent_id) : nil
    end

    # For display purposes (to_s)
    def to_s
      if @parent
        "##{@parent.id}: #{@parent.subject}"
      elsif @id
        "##{@id}"
      else
        ""
      end
    end

    # For aggregation and grouping (acts like the integer ID)
    def to_i
      @id.to_i
    end

    # For comparisons
    def ==(other)
      case other
      when ParentIdValue
        @id == other.id
      when Integer
        @id == other
      else
        @id.to_s == other.to_s
      end
    end

    def hash
      @id.hash
    end

    def eql?(other)
      self == other
    end

    # Make it behave like the ID for sorting
    def <=>(other)
      @id.to_i <=> (other.is_a?(ParentIdValue) ? other.id.to_i : other.to_i)
    end

    # Return the ID for database queries
    def present?
      @id.present?
    end

    def blank?
      @id.blank?
    end
  end

  module IssueQueryPatch
    def self.included(base)
      base.class_eval do

        # ----------------------------------------------------
        # 1. Set default grouping to parent_id
        # ----------------------------------------------------
        alias_method :initialize_without_parent_grouping, :initialize
        def initialize(*args)
          initialize_without_parent_grouping(*args)

          settings = Setting.plugin_parent_grouping || {}

          # Set default group_by to parent_id if default_grouping is enabled
          if settings['enabled'] == '1' && settings['default_grouping'] == '1' && self.group_by.blank?
            self.group_by = 'parent_id'
          end
        end

        # ----------------------------------------------------
        # 2. Make "Parent task" available as a column
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
        # 3. Make "Parent task" groupable
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
        # 4. KEY FIX: Override group_by_sort_order
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
        # 5. Override sort_clause for SUBTASK ordering
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
        # 6. Default sort criteria when grouping by parent
        # ----------------------------------------------------
        alias_method :default_sort_criteria_without_parent_grouping, :default_sort_criteria
        def default_sort_criteria
          settings = Setting.plugin_parent_grouping || {}

          # Only apply when enabled, grouping by parent_id, and no sort criteria set
          if settings['enabled'] == '1' && group_by.to_s == 'parent_id'
            group_order = settings['root_sort'].to_s.strip.downcase == 'asc' ? 'asc' : 'desc'
            subtask_order = settings['subtask_sort'].to_s.strip.downcase == 'asc' ? 'asc' : 'desc'

            return [['parent_id', group_order], ['id', subtask_order]]
          end

          default_sort_criteria_without_parent_grouping
        end

        # ----------------------------------------------------
        # 7. Preserve sort after params rebuild
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

        # ----------------------------------------------------
        # 8. Override group_by_column to use custom value class
        # ----------------------------------------------------
        alias_method :group_by_column_without_parent_grouping, :group_by_column
        def group_by_column
          column = group_by_column_without_parent_grouping

          # Only customize for parent_id grouping
          if column && column.name == :parent_id
            original_value_method = column.method(:value)

            column.define_singleton_method(:value) do |object|
              parent_id = original_value_method.call(object)
              ParentGrouping::ParentIdValue.new(parent_id)
            end
          end

          column
        end

      end
    end
  end
end