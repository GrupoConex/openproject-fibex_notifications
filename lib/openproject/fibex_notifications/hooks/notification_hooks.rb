module FibexNotifications
  module Hooks
    class NotificationHooks
      def self.register!
        OpenProject::Notifications.subscribe("notification_sent") do |payload|
          deliver_from_payload(payload)
        end

        OpenProject::Notifications.subscribe("notification_created") do |payload|
          deliver_from_payload(payload)
        end
      end

      def self.deliver_from_payload(payload)
        notification = payload[:notification]
        return unless notification

        NotificationService.deliver(notification:)
      rescue StandardError => e
        Rails.logger.error("[FibexNotifications] Hook error: #{e.message}")
      end
    end
  end
end

Rails.application.config.after_initialize do
  FibexNotifications::Hooks::NotificationHooks.register!
end
