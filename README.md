# OpenProject Fibex Notifications Plugin

Plugin de notificaciones multicanal para OpenProject que envía notificaciones a través del microservicio [fibex-communications](https://github.com/fibex/fibex-communications).

Canales soportados:
- **Email** — vía SMTP
- **WhatsApp** — vía Meta Graph API
- **SMS** — vía Tedexis API

Autenticación: **Keycloak M2M** (client_credentials grant)

## Requisitos

- OpenProject >= 14.0
- Ruby >= 3.1
- Servicio `fibex-communications` en funcionamiento
- Cliente M2M en Keycloak con permisos para consumir la API

## Instalación

1. Clonar el plugin dentro del directorio de plugins de OpenProject:

```bash
cd /path/to/openproject
git clone https://github.com/fibex/openproject-fibex_notifications plugins/fibex_notifications
```

2. Agregar la dependencia al `Gemfile.plugins` de OpenProject:

```ruby
gem 'openproject-fibex_notifications', path: 'plugins/fibex_notifications'
```

3. Instalar dependencias y ejecutar migraciones:

```bash
bundle install
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails assets:precompile
```

4. Reiniciar OpenProject.

## Configuración

1. Ir a **Administración → Fibex Notifications**
2. Sección **API fibex-communications**:
   - **API Endpoint**: `https://api.fibex.ai`
3. Sección **Keycloak M2M**:
   - **Token Endpoint**: `https://auth.fibex.ai/realms/{realm}/protocol/openid-connect/token`
   - **Client ID**: ID del cliente M2M en Keycloak
   - **Client Secret**: Secreto del cliente M2M
4. Activar **Enabled** y los canales deseados
5. Guardar

El plugin obtiene automáticamente un token vía `client_credentials`, lo cachea y lo refresca antes de que expire (con 30s de margen).

## Campos personalizados para usuarios

Para WhatsApp y SMS:

1. **Administración → Campos personalizados → Usuario → + Nuevo campo**
2. Crear campo `String` con internal name `whatsapp_phone`
3. Crear campo `String` con internal name `sms_phone`
4. Los usuarios completan sus números en su perfil

## Flujo de autenticación

```
OpenProject                              Keycloak
┌──────────────────┐                    ┌──────────────┐
│ FibexApiClient   │  POST /token       │              │
│ obtiene token   │──────────────────▶  │  client_id   │
│ client_creds     │◀──────────────────  │  + secret    │
│                  │     access_token    └──────────────┘
│ cachea y         │
│ refresca antes   │
│ de expiry (-30s) │
└──────────────────┘
       │
       │ Authorization: Bearer <token>
       ▼
fibex-communications (api.fibex.ai)
```

## Arquitectura

```
OpenProject                        fibex-communications (Rust/Axum)
┌────────────────┐                ┌──────────────────────────────┐
│ Notification    │  HTTP Bearer   │  POST /v1/emails/send        │
│ Hooks          │──────────────▶ │  POST /v1/whatsapp/send      │
│                 │                │  POST /v1/sms/send            │
│ Notification    │                │                              │
│ Service         │                │  ┌─ EmailSender (Lettre SMTP) │
│                 │                │  ├─ WhatsAppSender (Meta API) │
│ FibexApiClient  │                │  └─ SmsSender (Tedexis)      │
└────────────────┘                └──────────────────────────────┘
```

## Licencia

GPL-3.0
