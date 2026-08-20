class Rack::Attack
  # Throttle general API requests by IP
  throttle("api/ip", limit: 300, period: 5.minutes) do |req|
    req.ip if req.path.start_with?("/api")
  end

  # Throttle login attempts by IP
  throttle("login/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/api/login" && req.post?
  end

  # Throttle login attempts by email
  throttle("login/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/login" && req.post?
      req.params.dig("email") || req.params.dig("user", "email")
    end
  end

  # Throttle registration attempts by IP
  throttle("register/ip", limit: 3, period: 1.minute) do |req|
    req.ip if req.path == "/api/register" && req.post?
  end

  # Block requests with suspicious user agents
  blocklist("block/bad_agents") do |req|
    # Block requests with no user agent or known bad bots
    req.user_agent.blank? || req.user_agent =~ /sqlmap|nikto|nessus|masscan/i
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    retry_after = (env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [ { error: "Rate limit exceeded. Please try again later." }.to_json ]
    ]
  end
end

# Enable Rack::Attack in all environments
Rails.application.config.middleware.use Rack::Attack
