class CreateVersionChanges < Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
    def self.up
        create_table :version_changes do |t|
            t.integer  :project_id
            t.integer  :version_id
            t.integer  :author_id
            t.string   :name
            t.string   :old_value
            t.string   :value
            t.datetime :created_on
            t.datetime :updated_on
        end
        add_index :version_changes, :version_id
        add_index :version_changes, :project_id
    end

    def self.down
        drop_table :version_changes
    end
end
