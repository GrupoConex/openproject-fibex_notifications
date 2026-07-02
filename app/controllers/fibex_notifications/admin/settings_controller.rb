module FibexNotifications
  module Admin
    class SettingsController < ::Admin::SettingsController
      before_action :find_setting, only: %i[show update]

      def show
        render "fibex_notifications/admin/settings"
      end

      def update
        if @setting.update(permitted_params)
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to action: :show
        else
          render "fibex_notifications/admin/settings", status: :unprocessable_entity
        end
      end

      private

      def find_setting
        @setting = ::FibexNotificationSetting.first_or_initialize
      end

      def permitted_params
        params.require(:fibex_notification_setting).permit(
          :api_endpoint,
          :keycloak_token_endpoint,
          :keycloak_client_id,
          :keycloak_client_secret,
          :enabled,
          :email_enabled,
          :whatsapp_enabled,
          :sms_enabled,
          :default_from_name
        )
      end
    end
  end
end
