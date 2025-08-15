class AuthController < ApplicationController
  # Skip normal access token authentication for signup, signin, refresh, revoke
  skip_before_action :authenticate_request!, only: %i[signup signin refresh revoke]
  # Use refresh-token authentication only for refresh or revoke when all param is absent
  before_action :authenticate_with_refresh_token!, only: %i[refresh revoke], if: -> { params[:all].blank? }
  # Use access-token authentication only for revoke when all param is present
  before_action :authenticate_request!, only: %i[revoke], if: -> { params[:all].present? }

  # POST /auth/signup
  def signup
    user = User.create!(signup_params)
    json_notice("User signed up successfully", status: :created, **token_pair_for(user))
  end

  # POST /auth/signin
  def signin
    user = User.find_by(email: params[:email].to_s.downcase)
    if user&.authenticate(params[:password])
      json_notice("User signed in successfully", **token_pair_for(user))
    else
      json_error(error: "Invalid email or password", status: :unauthorized)
    end
  end

  # POST /auth/refresh
  def refresh
    token = @refresh_token # set in authenticate_with_refresh_token!
    token.revoke! # rotate
    json_notice("Refreshed tokens successfully", **token_pair_for(token.user))
  end

  # DELETE /auth/revoke
  def revoke
    if params[:all].present?
      current_user.refresh_tokens.active.update_all(revoked_at: Time.current)
    else
      @refresh_token.revoke!
    end

    head :no_content
  end

  private

  def signup_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def token_pair_for(user)
    access_ttl  = Rails.configuration.x.jwt.access_ttl
    refresh_ttl = Rails.configuration.x.jwt.refresh_ttl

    access_token = JsonWebToken.encode({ sub: user.id }, exp_seconds: access_ttl)
    refresh_token_raw, _record = issue_refresh_token!(user, ttl: refresh_ttl)

    {
      token_type: "Bearer",
      access_token: access_token,
      expires_in: access_ttl,
      refresh_token: refresh_token_raw
    }
  end

  def issue_refresh_token!(user, ttl:)
    jti = SecureRandom.uuid
    raw = SecureRandom.hex(32)
    digest = digest_refresh_token(raw)

    record = user.refresh_tokens.create!(
      jti: jti,
      token_digest: digest,
      expires_at: ttl.seconds.from_now,
      user_agent: request.user_agent.to_s.first(255),
      ip: request.remote_ip
    )

    [ raw, record ]
  end

  def digest_refresh_token(raw)
    Digest::SHA256.hexdigest(raw)
  end

  def find_refresh_token_by_raw(raw)
    digest = digest_refresh_token(raw)
    RefreshToken.find_by(token_digest: digest)
  end

  # Custom refresh token auth
  def authenticate_with_refresh_token!
    raw_token = params[:refresh_token].to_s
    return json_error("Missing refresh token", status: :bad_request) if raw_token.blank?

    token = find_refresh_token_by_raw(raw_token)
    return json_error("Invalid refresh token", status: :unauthorized) unless token&.active?

    @refresh_token = token
  end
end
