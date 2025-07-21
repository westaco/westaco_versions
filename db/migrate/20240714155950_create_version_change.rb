class CreateVersionChange < ActiveRecord::Migration[6.1]
  def change
    drop_table :version_changes, if_exists: true
    create_table :version_changes do |t|
      t.integer :project_id, null: false, index: true
      t.integer :version_id, null: false, index: true
      t.string :name, limit: 30, default: "", null: false
      t.string :old_value, limit: 30, default: "", null: false
      t.string :value, limit: 30, default: "", null: false
      t.string :description, default: ""
      t.integer :updated_by_id
      t.datetime :created_on, null: false
      t.datetime :updated_on

      t.timestamps
    end
  end
end
