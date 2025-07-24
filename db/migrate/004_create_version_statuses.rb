class CreateVersionStatuses < Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
    def self.up
        create_table :version_statuses do |t|
            t.string  :key,       :null => false
            t.string  :name
            t.boolean :is_closed, :default => false, :null => false
            t.integer :position
        end
        add_index :version_statuses, :key, :unique => true
    end

    def self.down
        drop_table :version_statuses
    end
end
