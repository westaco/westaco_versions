class PopulateVersionsDates < ActiveRecord::Migration

    def self.up
        Version.where(:closed_on => nil, :status => 'closed')
               .update_all('closed_on = updated_on')
        Version.where(:start_date => nil)
               .update_all("#{Version.table_name}.start_date = (SELECT MIN(#{Issue.table_name}.start_date) FROM #{Issue.table_name} WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id)")
        Version.where(:end_date => nil, :status => 'closed')
               .update_all("#{Version.table_name}.end_date = (SELECT MAX(#{Issue.table_name}.due_date) FROM #{Issue.table_name} WHERE #{Issue.table_name}.fixed_version_id = #{Version.table_name}.id)")
    end

    def self.down
        Version.where('closed_on = updated_on').update_all(:closed_on => nil)
    end

end
