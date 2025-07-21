class VersionStatus < ApplicationRecord
  include Redmine::SafeAttributes

  acts_as_positioned

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => true
  validates_length_of :name, :maximum => 30
  validates_presence_of :key
  validates_uniqueness_of :key
  validates_length_of :key, :maximum => 30
  validates_length_of :description, :maximum => 255

  scope :sorted, lambda {order(:position)}
  scope :named, lambda {|arg| where("LOWER(#{table_name}.name) = LOWER(?)", arg.to_s.strip)}

  safe_attributes(
    'name',
    'description',
    'is_closed',
    'position')

  before_validation :set_key

  private
  def set_key
    self.key = self.name.downcase.gsub(/[^a-z0-9]/, '_') unless self.key.present?
  end
end