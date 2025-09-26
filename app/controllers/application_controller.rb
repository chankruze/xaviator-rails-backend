class ApplicationController < ActionController::API
  before_action :authenticate_request!

  attr_reader :current_user

  rescue_from StandardError, with: :handle_api_exception

  def handle_api_exception(exception)
    case exception
    when ->(e) { e.message.include?("PG::") || e.message.include?("SQLite3::") }
      json_error(db_error_message(exception), status: :unprocessable_content)

    when ActionController::ParameterMissing
      json_error(exception, status: :bad_request)

    when ActiveRecord::RecordNotFound
      json_error("Couldn't find #{exception.model}", status: :not_found)

    when ActiveRecord::RecordNotUnique
      json_error(exception, status: :unprocessable_content)

    when ActiveModel::ValidationError, ActiveRecord::RecordInvalid, ArgumentError
      error_message = exception.message.gsub("Validation failed: ", "")
      json_error(error_message, status: :unprocessable_content)

    else
      handle_generic_exception(exception)
    end
  end

  def handle_generic_exception(exception, status = :internal_server_error)
    log_exception(exception) unless Rails.env.test?
    message = Rails.env.production? ? I18n.t("generic_error") : exception.message
    json_error(message, status: status)
  end

  def log_exception(exception)
    Rails.logger.error "[#{exception.class}] #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
  end

  def error_message(error)
    return error.to_s unless error.is_a?(StandardError)
    return error.record.errors_to_sentence if error.respond_to?(:record)

    error.message
  end

  def json_error(error, status: :unprocessable_entity, **context)
    render json: { error: error_message(error), **context }, status:
  end

  def json_notice(message, status: :ok, **extra)
    render status:, json: { message:, **extra }
  end

  def json_response(payload = {}, status: :ok)
    render status:, json: payload
  end

  private

  def db_error_message(exception)
    Rails.env.production? ? I18n.t("database_error") : exception.message
  end

  def authenticate_request!
    token = bearer_token
    return render_unauthorized(:missing_token) if token.blank?

    begin
      payload = JsonWebToken.decode(token)
      @current_user = User.find_by(id: payload[:sub])
      render_unauthorized(:invalid_user) if @current_user.nil?
    rescue JsonWebToken::Expired
      render_unauthorized(:token_expired)
    rescue JsonWebToken::Invalid => e
      render_unauthorized(:invalid_token, detail: e.message)
    end
  end

  def bearer_token
    auth = request.headers["Authorization"].to_s
    scheme, token = auth.split(" ", 2)
    scheme&.casecmp("Bearer")&.zero? ? token : nil
  end

  def render_unauthorized(error, detail: nil)
    response = { error: error }
    response[:detail] = detail if detail.present?
    render json: response, status: :unauthorized
  end
end
