class CreateFibexNotificationSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :fibex_notification_settings do |t|
      t.string :api_endpoint, null: false, default: ""
      t.string :keycloak_token_endpoint, null: false, default: ""
      t.string :keycloak_client_id, null: false, default: ""
      t.string :keycloak_client_secret, null: false, default: ""
      t.boolean :enabled, null: false, default: false
      t.boolean :email_enabled, null: false, default: true
      t.boolean :whatsapp_enabled, null: false, default: false
      t.boolean :sms_enabled, null: false, default: false
      t.string :default_from_name, null: false, default: "Fibex Notifications"
      t.timestamps
    end
  end
end
