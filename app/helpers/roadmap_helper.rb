module RoadmapHelper
    include Redmine::Export::PDF::IssuesPdfHelper

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
            item.status_name.capitalize
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

    def version_column_label(column, value)
        case column
        when :status
            l("version_status_#{value}").capitalize
        when :sharing
            l("label_version_sharing_#{value}")
        else
            value
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

    # We are reusing #calc_col_width - that's why we need to fake #issue_list
    def version_list(versions, &block)
        versions.each do |version|
            yield version, 0
        end
    end
    alias :issue_list :version_list

    # Alias some functions from IssuesPdfHelper for readability (and to avoid confusion)
    alias :get_versions_to_pdf_write_cells :get_issues_to_pdf_write_cells
    alias :versions_to_pdf_write_cells     :issues_to_pdf_write_cells

    # Rewrite of #fetch_row_values in IssuesPdfHelper
    def fetch_version_values(version, query)
        query.inline_columns.collect do |column|
            result = if column.is_a?(QueryCustomFieldColumn)
                custom_value = version.visible_custom_field_values.detect{ |value| value.custom_field_id == column.custom_field.id }
                show_value(custom_value, false)
            else
                value = version_column_label(column.name, version.send(column.name))
                if value.is_a?(Date)
                    format_date(value)
                elsif value.is_a?(Time)
                    format_time(value)
                elsif value.is_a?(Float)
                    sprintf('%.2f', value)
                else
                    value
                end
            end
            result.to_s
        end
    end

    # Many things copied from #issues_to_pdf
    def versions_to_pdf(versions, project, query)
        pdf = Redmine::Export::PDF::ITCPDF.new(current_language, 'L')
        title = query.new_record? ? l(:label_version_plural) : query.name
        title = "#{project} - #{title}" if project
        pdf.set_title(title)
        pdf.alias_nb_pages
        pdf.footer_date = format_date(User.current.today)
        pdf.set_auto_page_break(false)
        pdf.add_page('L')

        # Landscape A4 = 210 x 297 mm
        page_height   = pdf.get_page_height # 210
        page_width    = pdf.get_page_width  # 297
        left_margin   = pdf.get_original_margins['left'] # 10
        right_margin  = pdf.get_original_margins['right'] # 10
        bottom_margin = pdf.get_footer_margin
        row_height    = 4

        col_width   = []
        table_width = page_width - right_margin - left_margin
        unless query.inline_columns.empty?
            col_width   = calc_col_width(versions, query, table_width, pdf)
            table_width = col_width.inject(0, :+)
        end

        pdf.SetFontStyle('B', 11)
        pdf.RDMCell(190, 8, title)
        pdf.ln

        totals = query.totals.map{ |column, total| "#{column.caption}: #{total}" }
        if totals.present?
            pdf.SetFontStyle('B', 10)
            pdf.RDMCell(table_width, 6, totals.join('  '), 0, 1, 'R')
        end

        render_table_header(pdf, query, col_width, row_height, table_width)

        previous_group = false
        totals_by_group = query.totals_by_group
        result_count_by_group = query.result_count_by_group

        versions.each do |version|
            if query.grouped? && (group = query.group_by_column.value(version)) != previous_group
                pdf.SetFontStyle('B', 10)
                group_label = group.blank? ? 'None' : version_column_label(query.group_by_column.name, group.to_s.dup)
                group_label << " (#{result_count_by_group[group]})"
                pdf.bookmark(group_label, 0, -1)
                pdf.RDMCell(table_width, row_height * 2, group_label, 'LR', 1, 'L')
                pdf.SetFontStyle('', 8)

                totals = totals_by_group.map{ |column, total| "#{column.caption}: #{total[group]}"}.join('  ')
                pdf.RDMCell(table_width, row_height, totals, 'LR', 1, 'L') if totals.present?
                previous_group = group
            end

            col_values = fetch_version_values(version, query)

            base_y     = pdf.get_y
            max_height = get_versions_to_pdf_write_cells(pdf, col_values, col_width)
            space_left = page_height - base_y - bottom_margin
            if max_height > space_left
                pdf.add_page("L")
                render_table_header(pdf, query, col_width, row_height, table_width)
                base_y = pdf.get_y
            end

            versions_to_pdf_write_cells(pdf, col_values, col_width, max_height)
            pdf.set_y(base_y + max_height)
        end

        pdf.output
    end

end
