class User < ApplicationRecord
  include TokenAuthenticatable
  include PasswordResetable

  has_secure_password
  resourcify

  belongs_to :account
  has_and_belongs_to_many :products
  has_many :licenses, dependent: :destroy
  has_many :machines, through: :licenses
  has_one :token, as: :bearer, dependent: :destroy

  serialize :meta, Hash

  before_save -> { self.email = email.downcase }

  validates_associated :account, message: -> (_, obj) { obj[:value].errors.full_messages.first.downcase }
  validates :name, presence: true
  validates :email,
    presence: true,
    length: { maximum: 255 },
    format: { with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i },
    uniqueness: { case_sensitive: false, scope: :account_id }

  scope :roles, -> (*roles) {
    where role: roles
  }
  scope :product, -> (id) {
    includes(:products).where products: { id: Product.decode_id(id) || 0 }
  }
  scope :page, -> (page = {}) {
    paginate(page[:number]).per page[:size]
  }
end
