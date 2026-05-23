class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_super_admin

  def dashboard
    @branches = CooperativeBranch.all
    @total_users = User.count
    @total_branches = @branches.count
  end

  def branches
    @branches = CooperativeBranch.includes(:users).all
  end

  def show_branch
    @branch = CooperativeBranch.find(params[:id])
    @users = @branch.users.includes(:cooperative_branch)
  end

  def new_branch
    @branch = CooperativeBranch.new
  end

  def create_branch
    @branch = CooperativeBranch.new(branch_params)
    @branch.cooperative_bank_id = CooperativeBank.first&.id

    if @branch.save
      redirect_to admin_branches_path, notice: 'Branch created successfully.'
    else
      render :new_branch, status: :unprocessable_entity
    end
  end

  def edit_branch
    @branch = CooperativeBranch.find(params[:id])
  end

  def update_branch
    @branch = CooperativeBranch.find(params[:id])
    
    if @branch.update(branch_params)
      redirect_to admin_show_branch_path(@branch), notice: 'Branch updated successfully.'
    else
      render :edit_branch, status: :unprocessable_entity
    end
  end

  def destroy_branch
    @branch = CooperativeBranch.find(params[:id])
    
    if @branch.users.exists?
      redirect_to admin_branches_path, alert: 'Cannot delete branch with existing users. Please reassign users first.'
    else
      @branch.destroy
      redirect_to admin_branches_path, notice: 'Branch deleted successfully.'
    end
  end

  def users
    @users = User.includes(:cooperative_branch)
    @branches = CooperativeBranch.all

    # Filter by email
    if params[:email].present?
      @users = @users.where("email ILIKE ?", "%#{params[:email]}%")
    end

    # Filter by branch
    if params[:branch_id].present?
      @users = @users.where(cooperative_branch_id: params[:branch_id])
    end

    # Filter by status
    if params[:status].present?
      @users = params[:status] == "active" ? @users.active : @users.inactive
    end

    @users = @users.order(created_at: :desc)
  end

  def transfer_user
    @user = User.find(params[:id])

    if @user.super_admin?
      redirect_to admin_users_path, alert: 'Cannot transfer super admin user.'
      return
    end

    if @user.update(cooperative_branch_id: params[:branch_id])
      redirect_to admin_users_path, notice: "User transferred to #{@user.cooperative_branch.name} successfully."
    else
      redirect_to admin_users_path, alert: 'Failed to transfer user.'
    end
  end

  def toggle_user_status
    @user = User.find(params[:id])

    if @user.super_admin?
      redirect_to admin_users_path, alert: 'Cannot deactivate super admin user.'
      return
    end

    @user.update(active: !@user.active)
    status = @user.active? ? "activated" : "deactivated"
    redirect_to admin_users_path, notice: "User #{status} successfully."
  end

  def change_user_role
    @user = User.find(params[:id])

    if @user.super_admin?
      redirect_to admin_users_path, alert: 'Cannot change super admin role.'
      return
    end

    if params[:role].in?(%w[section_head manager staff])
      # If changing to section_head, remove branch assignment
      if params[:role] == "section_head"
        @user.update(role: params[:role], cooperative_branch_id: nil)
      else
        @user.update(role: params[:role])
      end
      redirect_to admin_users_path, notice: "User role changed to #{params[:role].humanize} successfully."
    else
      redirect_to admin_users_path, alert: 'Invalid role selected.'
    end
  end

  def new_user
    @user = User.new
    @branches = CooperativeBranch.all
  end

  def create_user
    @user = User.new(user_params)
    
    if @user.save
      redirect_to admin_users_path, notice: 'User created successfully.'
    else
      @branches = CooperativeBranch.all
      render :new_user, status: :unprocessable_entity
    end
  end

  def edit_user
    @user = User.find(params[:id])
    @branches = CooperativeBranch.all
  end

  def update_user
    @user = User.find(params[:id])
    
    if @user.update(user_params)
      redirect_to admin_users_path, notice: 'User updated successfully.'
    else
      @branches = CooperativeBranch.all
      puts "lllllllllllllllllllllll #{@user.errors.inspect}"
      render :edit_user, status: :unprocessable_entity
    end
  end

  def destroy_user
    @user = User.find(params[:id])

    if @user.super_admin?
      redirect_to admin_users_path, alert: 'Cannot delete super admin user.'
    else
      @user.destroy
      redirect_to admin_users_path, notice: 'User deleted successfully.'
    end
  end

  # Memberships
  def memberships
    @memberships = Member.includes(:cooperative_branch, :memberships, :creator).order(created_at: :desc)
    @branches = CooperativeBranch.all

    if params[:branch_id].present?
      @memberships = @memberships.where(cooperative_branch_id: params[:branch_id])
    end

    if params[:name].present?
      @memberships = @memberships.where("name ILIKE ?", "%#{params[:name]}%")
    end

    if params[:mobile].present?
      @memberships = @memberships.where("mobile_number ILIKE ?", "%#{params[:mobile]}%")
    end

    if params[:aadhaar].present?
      @memberships = @memberships.where("aadhaar_number ILIKE ?", "%#{params[:aadhaar]}%")
    end
  end

  def show_membership
    @member = Member.find(params[:id])
  end

  # Loan Applications
  def loan_applications
    @loan_applications = LoanApplication.includes(:member, :cooperative_branch, :creator).order(created_at: :desc)
    @branches = CooperativeBranch.all

    if params[:branch_id].present?
      @loan_applications = @loan_applications.where(cooperative_branch_id: params[:branch_id])
    end

    if params[:name].present?
      @loan_applications = @loan_applications.joins(:member).where("members.name ILIKE ?", "%#{params[:name]}%")
    end

    if params[:mobile].present?
      @loan_applications = @loan_applications.joins(:member).where("members.mobile_number ILIKE ?", "%#{params[:mobile]}%")
    end

    if params[:aadhaar].present?
      @loan_applications = @loan_applications.joins(:member).where("members.aadhaar_number ILIKE ?", "%#{params[:aadhaar]}%")
    end
  end

  def show_loan_application
    @loan_application = LoanApplication.find(params[:id])
  end

  # Jewel Loans
  def jewel_loans
    @jewel_loans = JewelLoan.includes(:member, :cooperative_branch, :creator).order(created_at: :desc)
    @branches = CooperativeBranch.all

    if params[:branch_id].present?
      @jewel_loans = @jewel_loans.where(cooperative_branch_id: params[:branch_id])
    end

    if params[:name].present?
      @jewel_loans = @jewel_loans.joins(:member).where("members.name ILIKE ?", "%#{params[:name]}%")
    end

    if params[:mobile].present?
      @jewel_loans = @jewel_loans.joins(:member).where("members.mobile_number ILIKE ?", "%#{params[:mobile]}%")
    end

    if params[:aadhaar].present?
      @jewel_loans = @jewel_loans.joins(:member).where("members.aadhaar_number ILIKE ?", "%#{params[:aadhaar]}%")
    end
  end

  def show_jewel_loan
    @jewel_loan = JewelLoan.find(params[:id])
  end

  # SHG Loans
  def shg_loans
    @shg_loans = ShgLoanApplication.includes(:self_help_group, :cooperative_branch, :creator, shg_loan_applicants: :shg_member).order(created_at: :desc)
    @branches = CooperativeBranch.all

    if params[:branch_id].present?
      @shg_loans = @shg_loans.where(cooperative_branch_id: params[:branch_id])
    end

    if params[:name].present?
      @shg_loans = @shg_loans.joins(shg_loan_applicants: :shg_member).where("shg_members.name ILIKE ?", "%#{params[:name]}%").distinct
    end

    if params[:mobile].present?
      @shg_loans = @shg_loans.joins(shg_loan_applicants: :shg_member).where("shg_members.mobile ILIKE ?", "%#{params[:mobile]}%").distinct
    end

    if params[:aadhaar].present?
      @shg_loans = @shg_loans.joins(shg_loan_applicants: :shg_member).where("shg_members.aadhar_number ILIKE ?", "%#{params[:aadhaar]}%").distinct
    end
  end

  def show_shg_loan
    @shg_loan = ShgLoanApplication.find(params[:id])
  end

  # Edit Requests (generic for all resource types)
  def edit_requests
    @edit_requests = EditRequest.includes(:user, :cooperative_branch, :approved_by).order(created_at: :desc)
    @branches = CooperativeBranch.all

    if params[:branch_id].present?
      @edit_requests = @edit_requests.where(cooperative_branch_id: params[:branch_id])
    end

    if params[:resource_type].present?
      @edit_requests = @edit_requests.where(resource_type: params[:resource_type])
    end

    if params[:status].present?
      case params[:status]
      when "pending"
        @edit_requests = @edit_requests.pending
      when "approved"
        @edit_requests = @edit_requests.approved_requests
      when "rejected"
        @edit_requests = @edit_requests.rejected
      end
    end
  end

  def approve_edit_request
    @edit_request = EditRequest.find(params[:id])
    @edit_request.approve!(current_user)
    redirect_to admin_edit_requests_path, notice: 'Edit request approved. Staff can now edit the resource.'
  end

  def reject_edit_request
    @edit_request = EditRequest.find(params[:id])
    @edit_request.reject!(current_user, params[:rejection_reason])
    redirect_to admin_edit_requests_path, notice: 'Edit request rejected.'
  end

  # Interest Rates
  def interest_rates
    @interest_rates = InterestRate.order(:loan_type, :min_amount)
  end

  def new_interest_rate
    @interest_rate = InterestRate.new
  end

  def create_interest_rate
    @interest_rate = InterestRate.new(interest_rate_params)

    if @interest_rate.save
      redirect_to admin_interest_rates_path, notice: 'Interest rate created successfully.'
    else
      render :new_interest_rate, status: :unprocessable_entity
    end
  end

  def edit_interest_rate
    @interest_rate = InterestRate.find(params[:id])
  end

  def update_interest_rate
    @interest_rate = InterestRate.find(params[:id])

    if @interest_rate.update(interest_rate_params)
      redirect_to admin_interest_rates_path, notice: 'Interest rate updated successfully.'
    else
      render :edit_interest_rate, status: :unprocessable_entity
    end
  end

  def destroy_interest_rate
    @interest_rate = InterestRate.find(params[:id])
    @interest_rate.destroy
    redirect_to admin_interest_rates_path, notice: 'Interest rate deleted successfully.'
  end

  def toggle_interest_rate
    @interest_rate = InterestRate.find(params[:id])
    @interest_rate.update(active: !@interest_rate.active)
    status = @interest_rate.active? ? "activated" : "deactivated"
    redirect_to admin_interest_rates_path, notice: "Interest rate #{status} successfully."
  end

  # Loan Types
  def loan_types
    @loan_types = LoanType.order(:code)
  end

  def new_loan_type
    @loan_type = LoanType.new
  end

  def create_loan_type
    @loan_type = LoanType.new(loan_type_params)

    if @loan_type.save
      redirect_to admin_loan_types_path, notice: 'Loan type created successfully.'
    else
      render :new_loan_type, status: :unprocessable_entity
    end
  end

  def edit_loan_type
    @loan_type = LoanType.find(params[:id])
  end

  def update_loan_type
    @loan_type = LoanType.find(params[:id])

    if @loan_type.update(loan_type_params)
      redirect_to admin_loan_types_path, notice: 'Loan type updated successfully.'
    else
      render :edit_loan_type
    end
  end

  def destroy_loan_type
    @loan_type = LoanType.find(params[:id])
    @loan_type.destroy
    redirect_to admin_loan_types_path, notice: 'Loan type deleted successfully.'
  end

  def toggle_loan_type
    @loan_type = LoanType.find(params[:id])
    @loan_type.update(active: !@loan_type.active)
    status = @loan_type.active? ? "activated" : "deactivated"
    redirect_to admin_loan_types_path, notice: "Loan type #{status} successfully."
  end

  # Loan Purposes
  def loan_purposes
    @loan_purposes = LoanPurpose.order(:name)
  end

  def new_loan_purpose
    @loan_purpose = LoanPurpose.new
  end

  def create_loan_purpose
    @loan_purpose = LoanPurpose.new(loan_purpose_params)

    if @loan_purpose.save
      redirect_to admin_loan_purposes_path, notice: 'Loan purpose created successfully.'
    else
      render :new_loan_purpose
    end
  end

  def edit_loan_purpose
    @loan_purpose = LoanPurpose.find(params[:id])
  end

  def update_loan_purpose
    @loan_purpose = LoanPurpose.find(params[:id])

    if @loan_purpose.update(loan_purpose_params)
      redirect_to admin_loan_purposes_path, notice: 'Loan purpose updated successfully.'
    else
      render :edit_loan_purpose
    end
  end

  def destroy_loan_purpose
    @loan_purpose = LoanPurpose.find(params[:id])
    @loan_purpose.destroy
    redirect_to admin_loan_purposes_path, notice: 'Loan purpose deleted successfully.'
  end

  def toggle_loan_purpose
    @loan_purpose = LoanPurpose.find(params[:id])
    @loan_purpose.update(active: !@loan_purpose.active)
    status = @loan_purpose.active? ? "activated" : "deactivated"
    redirect_to admin_loan_purposes_path, notice: "Loan purpose #{status} successfully."
  end


  # ── TERM DEPOSIT TYPES ──
  def term_deposit_types
    @term_deposit_types = TermDepositType.order(:name)
  end

  def new_term_deposit_type
    @term_deposit_type = TermDepositType.new
  end

  def create_term_deposit_type
    @term_deposit_type = TermDepositType.new(term_deposit_type_params)
    @term_deposit_type.active = true
    if @term_deposit_type.save
      redirect_to admin_term_deposit_types_path, notice: "Term deposit type created successfully."
    else
      render :new_term_deposit_type
    end
  end

  def edit_term_deposit_type
    @term_deposit_type = TermDepositType.find(params[:id])
  end

  def update_term_deposit_type
    @term_deposit_type = TermDepositType.find(params[:id])
    if @term_deposit_type.update(term_deposit_type_params)
      redirect_to admin_term_deposit_types_path, notice: "Term deposit type updated successfully."
    else
      render :edit_term_deposit_type
    end
  end

  def destroy_term_deposit_type
    TermDepositType.find(params[:id]).destroy
    redirect_to admin_term_deposit_types_path, notice: "Deleted successfully."
  end

  def toggle_term_deposit_type
    t = TermDepositType.find(params[:id])
    t.update(active: !t.active)
    redirect_to admin_term_deposit_types_path
  end


  def term_deposit_type_params
    params.require(:term_deposit_type).permit(:name, :description, :active)
  end
end

  private


  def ensure_super_admin
    unless current_user.super_admin? || current_user.section_head?
      redirect_to root_path, alert: 'Access denied. Super admin or Section Head privileges required.'
    end
  end

  def branch_params
    params.require(:cooperative_branch).permit(:name, :english_address, :kannada_address, :r_no, :phone_no, :manager_name, :manager_address)
  end

  def user_params
    permitted_params = params.require(:user).permit(:name, :email, :role, :cooperative_branch_id)

    if params[:user][:password].present?
      permitted_params = permitted_params.merge(
        params.require(:user).permit(:password, :password_confirmation)
      )
    end

    permitted_params
  end

  def interest_rate_params
    params.require(:interest_rate).permit(:loan_type, :loan_type_name, :rate, :min_amount, :max_amount, :active)
  end

  def loan_type_params
    params.require(:loan_type).permit(:code, :name, :description, :active)
  end

  def loan_purpose_params
    params.require(:loan_purpose).permit(:name, :description, :active)
  end
