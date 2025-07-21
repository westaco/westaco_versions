module WestacoVersionsControllerPatch
  def self.included(base)
    base.class_eval do
      before_action :find_allowed_statuses, only: [:new, :create, :edit, :update]

      private

      def find_allowed_statuses
        @allowed_statuses = VersionStatus.sorted
      end
    end
  end
end

unless VersionsController.included_modules.include?(WestacoVersionsControllerPatch)
  VersionsController.send(:include, WestacoVersionsControllerPatch)
end