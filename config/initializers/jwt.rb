Rails.application.config.x.jwt.secret      = ENV.fetch("JWT_SECRET", "dev_secret_change_me")
Rails.application.config.x.jwt.access_ttl  = (ENV["ACCESS_TTL"]  || 15.minutes.to_i).to_i  # seconds
Rails.application.config.x.jwt.refresh_ttl = (ENV["REFRESH_TTL"] || 7.days.to_i).to_i      # seconds
