class AddVersionsDates < ActiveRecord::Migration

    def self.up
        add_column :versions, :start_date, :date
        add_column :versions, :end_date,   :date
        add_column :versions, :closed_on,  :datetime
    end

    def self.down
        remove_column :versions, :start_date
        remove_column :versions, :end_date
        remove_column :versions, :closed_on
    end

end
