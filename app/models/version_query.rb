class VersionQuery < Query
    self.queried_class = Version
    self.view_permission = :view_issues

    self.available_columns = [
        QueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => true),
        QueryColumn.new(:name, :sortable => "#{Version.table_name}.name"),
        QueryColumn.new(:description, :sortable => "#{Version.table_name}.description"),
        QueryColumn.new(:effective_date, :sortable => "#{Version.table_name}.effective_date", :default_order => 'desc'),
        QueryColumn.new(:start_date, :sortable => "#{Version.table_name}.start_date", :default_order => 'desc'),
        QueryColumn.new(:end_date, :sortable => "#{Version.table_name}.end_date", :default_order => 'desc'),
        QueryColumn.new(:closed_on, :sortable => "#{Version.table_name}.closed_on", :default_order => 'desc'),
        QueryColumn.new(:sharing, :sortable => "#{Version.table_name}.sharing", :groupable => true),
        QueryColumn.new(:status, :sortable => "#{Version.table_name}.status", :groupable => true),
        QueryColumn.new(:default_version, :caption => :label_default, :sortable => "(#{Project.table_name}.default_version_id = #{Version.table_name}.id)"),
        QueryColumn.new(:created_on, :sortable => "#{Version.table_name}.created_on", :default_order => 'desc'),
        QueryColumn.new(:updated_on, :sortable => "#{Version.table_name}.updated_on", :default_order => 'desc'),
        QueryColumn.new(:done_ratio, :sortable => "COALESCE((SELECT AVG(CASE WHEN #{IssueStatus.table_name}.is_closed = #{connection.quoted_true} THEN 100 ELSE #{Issue.table_name}.done_ratio END) " +
                                                            "FROM #{Issue.table_name} " +
                                                            "JOIN #{IssueStatus.table_name} ON #{Issue.table_name}.status_id = #{IssueStatus.table_name}.id " +
                                                            "WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id), 0)"),
        QueryColumn.new(:issues_count, :caption => :label_issue_plural,
                                       :sortable => "(SELECT COUNT(*) FROM #{Issue.table_name} WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id)", :totalable => true),
        QueryColumn.new(:open_issues_count, :caption => :label_open_issues_count,
                                            :sortable => "(SELECT COUNT(*) FROM #{Issue.table_name} " +
                                                          "JOIN #{IssueStatus.table_name} ON #{Issue.table_name}.status_id = #{IssueStatus.table_name}.id " +
                                                          "WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id AND #{IssueStatus.table_name}.is_closed = #{connection.quoted_false})", :totalable => true),
        QueryColumn.new(:closed_issues_count, :caption => :label_closed_issues_count,
                                              :sortable => "(SELECT COUNT(*) FROM #{Issue.table_name} " +
                                                            "JOIN #{IssueStatus.table_name} ON #{Issue.table_name}.status_id = #{IssueStatus.table_name}.id " +
                                                            "WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id AND #{IssueStatus.table_name}.is_closed = #{connection.quoted_true})", :totalable => true),
        QueryColumn.new(:estimated_duration, :sortable => "CASE WHEN #{Version.table_name}.effective_date THEN DATEDIFF(#{Version.table_name}.effective_date, " +
                                                          "COALESCE(#{Version.table_name}.start_date, #{Version.table_name}.created_on)) ELSE NULL END", :default_order => 'desc'),
        QueryColumn.new(:duration, :sortable => "CASE WHEN #{Version.table_name}.start_date AND #{Version.table_name}.end_date THEN " +
                                                "DATEDIFF(#{Version.table_name}.end_date, #{Version.table_name}.start_date) ELSE NULL END", :default_order => 'desc'),
        QueryColumn.new(:remaining_duration, :sortable => "CASE WHEN (#{Version.table_name}.start_date IS NULL OR #{Version.table_name}.start_date <= CURDATE()) AND " +
                                                          "COALESCE(#{Version.table_name}.end_date, #{Version.table_name}.effective_date) >= CURDATE() THEN " +
                                                          "DATEDIFF(COALESCE(#{Version.table_name}.end_date, #{Version.table_name}.effective_date), CURDATE()) ELSE NULL END", :default_order => 'desc'),
        QueryColumn.new(:extra_duration, :sortable => "CASE WHEN #{Version.table_name}.effective_date AND #{Version.table_name}.end_date THEN " +
                                                      "DATEDIFF(#{Version.table_name}.end_date, #{Version.table_name}.effective_date) ELSE NULL END", :default_order => 'desc'),
        QueryColumn.new(:estimated_hours, :sortable => "COALESCE((SELECT SUM(estimated_hours) FROM #{Issue.table_name} WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id), 0)",
                                          :default_order => 'desc', :totalable => true)
    ]

    def initialize(attributes = nil, *args)
        super(attributes)
        self.filters ||= { 'status' => { :operator => 'o', :values => [ '' ] } }
    end

    def initialize_available_filters
        add_available_filter('status', :type => :list_status,
                                       :values => Version::VERSION_STATUSES.map{ |status| [ l("version_status_#{status}"), status ] })
        add_available_filter('project_id', :type => :list,
                                           :values => lambda { project_values }) if project.nil?
        add_available_filter('subproject_id', :type => :list_subprojects,
                                              :values => lambda { subproject_values }) if project && !project.leaf?
        add_available_filter('name', :type => :string)
        add_available_filter('description', :type => :text)
        add_available_filter('effective_date', :type => :date)
        add_available_filter('start_date', :type => :date)
        add_available_filter('end_date', :type => :date)
        add_available_filter('closed_on', :type => :date_past)
        add_available_filter('sharing', :type => :list,
                                        :values => Version::VERSION_SHARINGS.map{ |sharing| [ l("label_version_sharing_#{sharing}"), sharing ] })
        add_available_filter('project.default_version_id', :type => :list,
                                                           :name => l(:label_attribute_of_project, :name => l(:field_default_version)),
                                                           :values => [ [ l(:general_text_yes), '1' ], [ l(:general_text_no), '0' ] ])
        add_available_filter('created_on', :type => :date_past)
        add_available_filter('updated_on', :type => :date_past)

        add_custom_fields_filters(VersionCustomField)
        add_associations_custom_fields_filters(:project)
    end

    def available_columns
        return @available_columns if @available_columns
        @available_columns = self.class.available_columns.dup
        if User.current.allowed_to?(:view_time_entries, project, :global => true)
            @available_columns << QueryColumn.new(:spent_hours, :caption => :label_spent_time,
                                                  :sortable => "COALESCE((SELECT SUM(hours) FROM #{TimeEntry.table_name} " +
                                                                         "JOIN #{Issue.table_name} ON #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id " +
                                                                         "WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id), 0)", :default_order => 'desc', :totalable => true)
        end
        if User.current.allowed_to?(:view_wiki_pages, project, :global => true)
            @available_columns << QueryColumn.new(:wiki_page_title, :caption => :label_wiki_page)
        end
        @available_columns += VersionCustomField.visible.map{ |field| QueryCustomFieldColumn.new(field) }
        @available_columns
    end

    def default_columns_names
        @default_columns_names ||= begin
            default_columns = [ :name, :effective_date, :description, :status, :sharing, :wiki_page_title ]
            project.present? ? default_columns : [ :project ] | default_columns
        end
    end

    def default_sort_criteria
        @default_sort_criteria ||= begin
            sort_criteria = [ [ 'effective_date', 'desc' ], 'name' ]
            project.present? ? sort_criteria : [ 'project' ] | sort_criteria
        end
    end

    def base_scope
        Version.visible.joins(:project).where(statement)
    end

    def results_scope
        order_option = [ group_by_sort_order, sort_clause ].flatten.reject(&:blank?)
        base_scope.order(order_option)
                  .joins(joins_for_order_statement(order_option.join(',')))
    end

    def sql_for_status_field(field, operator, value)
        case operator
        when 'o'
            "#{Version.table_name}.status = 'open'"
        when 'c'
            "#{Version.table_name}.status = 'closed'"
        else
            sql_for_field(field, operator, value, Version.table_name, 'status')
        end
    end

    def sql_for_project_default_version_id_field(field, operator, value)
        if value.is_a?(Array) && value.count > 1 && value.include?('1') && value.include?('0')
            nil
        else
            value = value.detect{ |item| [ '1', '0' ].include?(item) } if value.is_a?(Array)
            if operator == '!' ? value == '1' : value == '0'
                "(#{Project.table_name}.default_version_id IS NULL OR #{Project.table_name}.default_version_id != #{Version.table_name}.id)"
            else
                "#{Project.table_name}.default_version_id = #{Version.table_name}.id"
            end
        end
    end

    def total_for_issues_count(scope)
        map_total(scope.joins(:fixed_issues).count("#{Issue.table_name}.id")){ |total| total.to_i }
    end

    def total_for_open_issues_count(scope)
        map_total(scope.joins(:fixed_issues).merge(Issue.open(true)).count("#{Issue.table_name}.id")){ |total| total.to_i }
    end

    def total_for_closed_issues_count(scope)
        map_total(scope.joins(:fixed_issues).merge(Issue.open(false)).count("#{Issue.table_name}.id")){ |total| total.to_i }
    end

    def total_for_estimated_hours(scope)
        map_total(scope.joins(:fixed_issues).sum(:estimated_hours)){ |total| total.to_f.round(2) }
    end

    def total_for_spent_hours(scope)
        total_scope = scope.joins(:fixed_issues => :time_entries).where(TimeEntry.visible_condition(User.current)).sum("#{TimeEntry.table_name}.hours")
        map_total(total_scope){ |total| total.to_f.round(2) }
    end

end
