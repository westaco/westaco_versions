class AddVersionsStatusIndex < ActiveRecord::Migration

    def self.up
        add_index :versions, :status
    end

    def self.down
        remove_index :versions, :status
    end

end
