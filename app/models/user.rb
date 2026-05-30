class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :cooperative_branch, optional: true

  validates :cooperative_branch, presence: true, unless: :head_office_user?

  enum :role, {
                super_admin: "super_admin",
                section_head: "section_head",
                manager: "manager",
                staff: "staff"
              }, prefix: true # optional: gives you methods like user.role_manager?

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Head office users don't need a branch
  def head_office_user?
    super_admin? || section_head?
  end

  def super_admin?
    role == "super_admin"
  end

  def section_head?
    role == "section_head"
  end

  def manager?
    role == "manager"
  end

  def staff?
    role == "staff"
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_deactivated
  end
end
