module FibexNotifications
  class Engine < ::Rails::Engine
    engine_name 'fibex_notifications'

    config.autoload_paths += %w[
      app/services
      app/models/concerns
    ]

    initializer 'fibex_notifications.register_hooks' do
      require_relative 'hooks/notification_hooks'
    end

    initializer 'fibex_notifications.append_migrations' do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |migration_path|
          app.config.paths['db/migrate'] << migration_path
        end
      end
    end

    initializer 'fibex_notifications.admin_menu', after: :load_config_initializers do
      if defined?(::Admin::Menu)
        ::Admin::Menu.items.push(
          ::Admin::MenuItem.new(
            id: 'fibex_notifications',
            label: 'fibex_notifications.admin.settings.title',
            path: -> { admin_fibex_settings_path },
            icon: 'icon-broadcast'
          )
        )
      end
    end
  end
end
