class FibexNotificationSetting < ApplicationRecord
  validates :api_endpoint, presence: true, url: true
  validates :keycloak_token_endpoint, presence: true, url: true
  validates :keycloak_client_id, presence: true
  validates :keycloak_client_secret, presence: true

  encrypts :keycloak_client_secret
end
