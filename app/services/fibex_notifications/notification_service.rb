module FibexNotifications
  class NotificationService
    class << self
      def deliver(notification:)
        return unless fibex_enabled?
        return if notification.recipient.nil?

        user = notification.recipient
        channels = enabled_channels_for(user)

        return if channels.empty?

        subject = notification_subject(notification)
        text_body = notification_body(notification)
        metadata = notification_metadata(notification)

        channels.each do |channel|
          send_to_channel(channel, user, subject:, text: text_body, metadata:)
        end
      end

      private

      def fibex_enabled?
        ::FibexNotificationSetting.exists?(enabled: true)
      end

      def enabled_channels_for(user)
        channels = []
        setting = ::FibexNotificationSetting.first

        return channels unless setting

        channels << :email if setting.email_enabled && user.mail.present?
        channels << :whatsapp if setting.whatsapp_enabled && user.respond_to?(:whatsapp_phone) && user.whatsapp_phone.present?
        channels << :sms if setting.sms_enabled && user.respond_to?(:sms_phone) && user.sms_phone.present?

        channels
      end

      def send_to_channel(channel, user, subject:, text:, metadata:)
        client = build_client

        case channel
        when :email
          client.send_email(to: user.mail, subject:, text:, metadata:)
        when :whatsapp
          client.send_whatsapp(to: user.whatsapp_phone, text:, metadata:)
        when :sms
          client.send_sms(to: user.sms_phone, text:, metadata:)
        end
      rescue StandardError => e
        Rails.logger.error("[FibexNotifications] #{channel} delivery failed for user##{user.id}: #{e.message}")
      end

      def build_client
        setting = ::FibexNotificationSetting.first!
        FibexNotifications::FibexApiClient.new(
          base_url: setting.api_endpoint,
          keycloak_token_endpoint: setting.keycloak_token_endpoint,
          keycloak_client_id: setting.keycloak_client_id,
          keycloak_client_secret: setting.keycloak_client_secret
        )
      end

      def notification_subject(notification)
        case notification.resource_type
        when "WorkPackage"
          wp = notification.resource
          "[#{wp.project.name}] #{wp.subject}" if wp
        else
          I18n.t("fibex_notifications.notification.default_subject")
        end
      end

      def notification_body(notification)
        reason = notification.reason || "mentioned"
        actor_name = notification.actor&.name || I18n.t("fibex_notifications.notification.someone")

        case notification.resource_type
        when "WorkPackage"
          wp = notification.resource
          if wp
            I18n.t("fibex_notifications.notification.work_package_body",
                   actor: actor_name,
                   reason: I18n.t("fibex_notifications.reasons.#{reason}", default: reason),
                   subject: wp.subject,
                   project: wp.project.name,
                   url: "https://#{Setting.host_name}/work_packages/#{wp.id}")
          end
        else
          I18n.t("fibex_notifications.notification.generic_body",
                 actor: actor_name,
                 reason: I18n.t("fibex_notifications.reasons.#{reason}", default: reason))
        end
      end

      def notification_metadata(notification)
        {
          openproject: {
            notification_id: notification.id,
            resource_type: notification.resource_type,
            resource_id: notification.resource_id,
            reason: notification.reason,
            actor_id: notification.actor_id
          },
          source: "openproject-fibex_notifications"
        }
      end
    end
  end
end
