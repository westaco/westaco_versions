module RoadmapHelper

    # Wrapper around QueriesHelper#column_content (calls version_column_value)
    def version_column_content(column, item)
        if column.name == :default_version
            version_column_value(column, item, item == item.project.default_version)
        elsif column.name == :done_ratio
             version_column_value(column, item, [ item.closed_percent, item.completed_percent ])
        else
            value = column.value_object(item)
            if value.is_a?(Array)
                values = value.collect{ |v| version_column_value(column, item, v) }.compact
                safe_join(values, ', ')
            else
                version_column_value(column, item, value)
            end
        end
    end

    # Wrapper around QueriesHelper#column_value
    def version_column_value(column, item, value)
        case column.name
        when :name
            link_to(value, version_path(item))
        when :status
            l("version_status_#{value}").capitalize
        when :sharing
            l("label_version_sharing_#{value}")
        when :wiki_page_title
            if value.present? && !item.project.wiki.nil? && User.current.allowed_to?(:view_wiki_pages, item.project)
                link_to(value, { :controller => 'wiki', :action => 'show', :project_id => item.project, :id => Wiki.titleize(value) })
            else
                value
            end
        when :default_version
            checked_image value
        when :done_ratio
            progress_bar(value)
        when :estimated_duration, :duration, :remaining_duration
            l('datetime.distance_in_words.x_days', :count => value) if value
        when :extra_duration
            if value
                css_classes = [ 'duration' ]
                if value > 0
                    css_classes << 'overdue'
                elsif value < 0
                    css_classes << 'early'
                end
                content_tag('span', l('datetime.distance_in_words.x_days', :count => value), :class => css_classes.join(' '))
            end
        else
            column_value(column, item, value)
        end
    end

    def version_group_name(group_name)
        case @query.group_by_column.name
        when :status
            l("version_status_#{group_name}").capitalize
        when :sharing
            l("label_version_sharing_#{group_name}")
        else
            group_name
        end
    end

    def version_css_classes(version)
        css_classes = [ 'version', cycle('odd', 'even'), version.status ]
        css_classes << (version.completed? ? 'completed' : 'incompleted')
        unless version.closed?
            css_classes << 'behind-schedule' if version.behind_schedule?
            css_classes << 'overdue' if version.overdue?
        end
        css_classes << 'shared' if version.shared?
        css_classes
    end

end
