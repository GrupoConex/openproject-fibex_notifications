module FibexNotifications
  class FibexApiClient
    attr_reader :base_url, :idempotency_key

    def initialize(base_url:, keycloak_token_endpoint: nil, keycloak_client_id: nil, keycloak_client_secret: nil)
      @base_url = base_url
      @keycloak_token_endpoint = keycloak_token_endpoint
      @keycloak_client_id = keycloak_client_id
      @keycloak_client_secret = keycloak_client_secret
      @idempotency_key = SecureRandom.uuid
      @token = nil
      @token_expires_at = nil
      @mutex = Mutex.new
    end

    def send_email(to:, subject:, text: nil, html: nil, metadata: {})
      post("/v1/emails/send", {
        to:,
        subject:,
        text:,
        html:,
        metadata:
      })
    end

    def send_whatsapp(to:, text: nil, template: nil, metadata: {})
      post("/v1/whatsapp/send", {
        to:,
        type: "text",
        text: text ? { body: text, preview_url: false } : nil,
        template:,
        metadata:,
        recipient_type: "individual"
      })
    end

    def send_sms(to:, text:, metadata: {})
      post("/v1/sms/send", {
        to:,
        text: normalize_phone(to),
        metadata:
      })
    end

    def health
      conn.get("/v1/health")
    end

    private

    def post(path, body)
      response = conn.post(path) do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["Authorization"] = "Bearer #{access_token}"
        req.headers["Idempotency-Key"] = idempotency_key
        req.body = body.to_json
      end

      parse_response(response)
    end

    def conn
      @conn ||= Faraday.new(url: base_url) do |f|
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2
        f.response :raise_error
        f.adapter Faraday.default_adapter
      end
    end

    def access_token
      @mutex.synchronize do
        if @token.nil? || token_expired?
          obtain_token
        end
        @token
      end
    end

    def token_expired?
      @token_expires_at.nil? || Time.now >= @token_expires_at - 30
    end

    def obtain_token
      raise "Keycloak configuration required for M2M auth" unless @keycloak_token_endpoint && @keycloak_client_id && @keycloak_client_secret

      response = Faraday.post(@keycloak_token_endpoint) do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form({
          grant_type: "client_credentials",
          client_id: @keycloak_client_id,
          client_secret: @keycloak_client_secret
        })
      end

      unless response.success?
        raise "Keycloak token request failed: HTTP #{response.status} #{response.body}"
      end

      body = JSON.parse(response.body)
      @token = body["access_token"]
      expires_in = body["expires_in"] || 300
      @token_expires_at = Time.now + expires_in

      Rails.logger.info("[FibexNotifications] Obtained Keycloak M2M token, expires in #{expires_in}s")
    rescue JSON::ParserError => e
      raise "Keycloak token response parse error: #{e.message}"
    end

    def parse_response(response)
      result = JSON.parse(response.body)

      case response.status
      when 200
        { status: :duplicate, body: result }
      when 201
        { status: :sent, body: result }
      else
        { status: :error, error: result["error"] || "HTTP #{response.status}" }
      end
    rescue JSON::ParserError => e
      { status: :error, error: "Invalid response: #{e.message}" }
    end

    def normalize_phone(phone)
      digits = phone.gsub(/[^\d]/, "")

      if digits.start_with?("58") && digits.length == 12
        digits
      elsif digits.start_with?("0") && digits.length == 11
        "58#{digits[1..]}"
      elsif digits.length == 10
        "58#{digits}"
      else
        digits
      end
    end
  end
end
