class LoadVersionStatusData < ActiveRecord::Migration[6.1]
  def change
    Version::VERSION_STATUSES.each do |key|
      attrs = { key: key, name: I18n.t("version_status_#{key}") }
      attrs[:is_closed] = true if ['closed', 'locked'].include?(key)

      VersionStatus.where(attrs).first_or_create
    end
  end
end
