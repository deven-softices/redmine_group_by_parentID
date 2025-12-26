# frozen_string_literal: true

module ParentGrouping
  module QueriesHelperPatch
    # Override format_object to customize how parent_id values are displayed in group headers
    # This method is called by Redmine when rendering group labels
    def format_object(object, html = true)
      # Check if we're in a parent_id grouped query context
      if @query && @query.group_by == 'parent_id' && object.is_a?(Integer)
        parent = Issue.find_by(id: object)
        if parent
          if html
            link_to("##{parent.id}: #{parent.subject}", issue_path(parent))
          else
            "##{parent.id}: #{parent.subject}"
          end
        else
          "##{object}"
        end
      else
        super
      end
    end
  end
end

# Apply the patch
Rails.application.config.to_prepare do
  QueriesHelper.prepend(ParentGrouping::QueriesHelperPatch)
end
