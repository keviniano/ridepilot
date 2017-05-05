class User < ActiveRecord::Base
  acts_as_paranoid # soft delete
  has_paper_trail
  
  has_many   :roles, dependent: :destroy
  belongs_to :current_provider, class_name: "Provider", foreign_key: :current_provider_id
  has_one    :driver
  has_one    :device_pool_driver, through: :driver
  belongs_to :user_address, -> { with_deleted }, class_name: 'UserAddress', foreign_key: 'address_id'
  accepts_nested_attributes_for :user_address, update_only: true
  
  # Include default devise modules. Others available are:
  # :rememberable, :token_authenticatable, :confirmable, :lockable
  devise :database_authenticatable, :recoverable, :trackable, :validatable, 
    :timeoutable, :password_expirable, :password_archivable, :account_expireable

  # Let Devise handle the email format requirement
  validates :username, :email, uniqueness: { :case_sensitive => false, conditions: -> { where(deleted_at: nil) } }
  validates_presence_of :first_name, :last_name, :username
  validate :valid_phone_number
  
  # Let Devise handle the password length requirement
  validates :password, confirmation: true, format: {
    if: :password_required?,
    with: /\A(?=.*[0-9])(?=.*[A-Z])(.*)\z/,
    message: "must have at least one number and at least one capital letter"
  }
  
  before_validation do
    self.username = self.username.downcase if self.username.present?
    self.email = self.email.downcase if self.email.present?
  end
  
  def self.drivers(provider)
    Driver.where(:provider_id => provider.id).map(&:user)
  end
  
  # Generate a password that will validate properly for User
  def self.generate_password(length = 8)
    # Filter commonly confused characters
    charset = (('a'..'z').to_a + ('A'..'Z').to_a) - %w(i I l o O)
    result = (1..length).collect{|a| charset[rand(charset.size)]}.join
    # Pick two indices to replace with number and symbol
    indices = (0..length-1).to_a
    n = indices.sample
    m = (indices - [n]).sample
    # At least one number
    result[n] = '23456789'.chars.to_a.sample
    # At least one capital character
    result[m] = ('A'..'Z').to_a.sample
    return result
  end

  def update_password(params)
    unless params[:password].blank?
      self.update_with_password(params)
    else
      self.errors.add('password', :blank)
      false
    end
  end

  def update_email(params)
    unless params[:email].blank?
      self.email = params[:email]
      self.save
    else
      self.errors.add('email', :blank)
      false
    end
  end
  
  # super admin (aka system admin) is regardless of providers
  def super_admin?
    !roles.system_admins.empty?
  end

  def admin?
    super_admin? || roles.where(:provider_id => current_provider.id).first.try(:admin?)
  end
  
  def editor?
    super_admin? || roles.where(:provider_id => current_provider.id).first.try(:editor?)
  end

  def name
    "#{first_name} #{last_name}"
  end

  def display_name
    name.blank? ? email : name
  end

  def label_as_driver
    "#{last_name}, #{first_name} (#{username})"
  end

  private

  def valid_phone_number
    util = Utility.new
    if phone_number.present?
      errors.add(:phone_number, 'is invalid') unless util.phone_number_valid?(phone_number) 
    end
  end

end
