require "open_project/plugins"

module OpenProject::FibexNotifications
  class Engine < ::Rails::Engine
    engine_name :openproject_fibex_notifications

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-fibex_notifications",
             author_url: "https://fibex.ai",
             bundled: false do
      menu :admin_menu,
           :fibex_notifications,
           { controller: "/fibex_notifications/admin/settings", action: :show },
           caption: "Fibex Notifications",
           icon: "bell"
    end

    config.autoload_paths += %w[
      app/services
      app/models/concerns
    ]

    initializer "fibex_notifications.register_hooks" do
      require_relative "hooks/notification_hooks"
    end
  end
end
