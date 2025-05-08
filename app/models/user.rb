class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, length: { maximum: 50 }, allow_blank: true
  validates :last_name, length: { maximum: 50 }, allow_blank: true
end
