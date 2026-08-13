class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(n) { n.strip }

  validates :name, presence: true
  validates :email_address, uniqueness: true
  validates :password, length: { minimum: 8 }, allow_nil: true

  generates_token_for :email_confirmation, expires_in: 1.day do
    email_address
  end

  def confirmed?
    confirmed_at.present?
  end

  def confirm!
    update!(confirmed_at: Time.current)
  end

  def send_confirmation_email
    ConfirmationsMailer.confirm(self).deliver_later
  end
end
