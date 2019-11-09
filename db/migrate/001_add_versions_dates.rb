class AddVersionsDates < Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]

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
