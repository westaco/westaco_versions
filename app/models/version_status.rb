class VersionStatus < ActiveRecord::Base
    self.table_name = 'version_statuses'

    has_many :versions, :foreign_key => :status, :primary_key => :key

    validates :key, :presence => true, :uniqueness => true
    validates :name, :presence => true

    scope :sorted, -> { order(:position) }
end
