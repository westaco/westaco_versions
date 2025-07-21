class CreateVersionStatus < ActiveRecord::Migration[6.1]
  def change
    drop_table :version_statuses, if_exists: true
    create_table :version_statuses do |t|
      t.string :key, limit: 30, default: "", null: false
      t.string :name, limit: 30, default: "", null: false
      t.boolean :is_closed, default: false, null: false
      t.integer :position
      t.string :description
      t.timestamps

      t.index ["is_closed"], name: "index_version_statuses_on_is_closed"
      t.index ["position"], name: "index_version_statuses_on_position"
    end
  end
end
