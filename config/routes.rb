Rails.application.routes.draw do
  namespace :admin do
    resource :fibex_settings,
             only: %i[show update],
             controller: "fibex_notifications/admin/settings"
  end
end
