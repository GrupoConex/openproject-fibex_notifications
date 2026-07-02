module FibexNotifications
  module UserPatch
    def self.prepended(base)
      base.class_eval do
        prepend InstanceMethods
      end
    end

    module InstanceMethods
      def whatsapp_phone
        custom_field_value_by_key("whatsapp_phone")
      end

      def sms_phone
        custom_field_value_by_key("sms_phone")
      end
    end

    private

    def custom_field_value_by_key(key)
      cf = UserCustomField.find_by(member_only: false)
      cv = custom_values.joins(:custom_field)
                         .find_by(custom_fields: { internal_name: key })
      cv&.value.presence
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
