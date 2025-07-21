class AddVersionsStatusIndex < Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]

    def self.up
        add_index :versions, :status
    end

    def self.down
        remove_index :versions, :status
    end

end
