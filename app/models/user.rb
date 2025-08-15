class User < ApplicationRecord
  MIN_PASSWORD_LENGTH = 8
  MAX_EMAIL_LENGTH = 255

  # Associations
  has_many :refresh_tokens, dependent: :delete_all

  # Callbacks
  before_validation :downcase_email

  # Validations
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: MAX_EMAIL_LENGTH },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password,
            length: { minimum: MIN_PASSWORD_LENGTH },
            if: -> { password.present? }
  validates :password_confirmation,
            presence: true,
            on: :create

  has_secure_password

  private

  def downcase_email
    self.email = email.to_s.downcase.strip
  end
end
