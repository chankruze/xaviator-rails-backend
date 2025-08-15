class JsonWebToken
  ALGO   = "HS256"
  SECRET = -> { Rails.configuration.x.jwt.secret }

  class Expired < StandardError; end
  class Invalid < StandardError; end

  def self.encode(payload, exp_seconds:)
    payload = payload.dup
    payload[:exp] = (Time.now.to_i + exp_seconds.to_i)
    JWT.encode(payload, SECRET.call, ALGO)
  end

  def self.decode(token)
    body, = JWT.decode(token, SECRET.call, true, { algorithm: ALGO })
    body.with_indifferent_access
  rescue JWT::ExpiredSignature
    raise Expired, "token expired"
  rescue JWT::DecodeError => e
    raise Invalid, e.message
  end
end
