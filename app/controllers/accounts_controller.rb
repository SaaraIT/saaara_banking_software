class AccountsController < ApplicationController
  before_action :set_member, except: [:search_member]

  def index
    @accounts = @member.accounts.order(created_at: :desc)
  end
  def new
    @account = @member.accounts.build
  end

  def show
    @account = @member.accounts.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "account_#{@account.id}",
          template: "accounts/show",
          layout: "pdf",
          page_size: "A4"
      end
    end
  end

  def show
    @account = @member.accounts.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "account_#{@account.id}",
          template: "accounts/show",
          layout: "pdf",
          page_size: "A4"
      end
    end
  end

  def edit
    @account = @member.accounts.find(params[:id])
  end

  def create
    @account = @member.accounts.build(account_params)
    if @account.save
      redirect_to members_path, notice: "Account created successfully."
    else
      render :new
    end
  end

  def update
    @account = @member.accounts.find(params[:id])
    if @account.update(account_params)
      redirect_to members_path, notice: "Account updated successfully."
    else
      render :edit
    end
  end


def search_member
  q = params[:q].to_s.strip
  members = Member.where(cooperative_branch_id: Current.branch.id)
                  .where("name LIKE :q OR member_no LIKE :q", q: "%#{q}%")
                  .limit(10)
  render json: members.map { |m|
    {
      id:                     m.id,
      member_no:              m.member_no,
      name:                   m.name,
      aadhaar_number:         m.aadhaar_number,
      father_or_husband_name: m.father_or_husband_name,
      father_or_husband:      m.father_or_husband,
      address_a_building:     m.address_a_building,
      address_a_village:      m.address_a_village,
      address_a_district:     m.address_a_district,
      address_a_pincode:      m.address_a_pincode,
      address_b_building:     m.address_b_building,
      address_b_village:      m.address_b_village,
      address_b_district:     m.address_b_district,
      address_b_pincode:      m.address_b_pincode,
      mobile_number:          m.mobile_number
    }
  }
end



  private

  def set_member
    @member = Member.find(params[:member_id])
  end

  def account_params
    params.require(:account).permit(
      :date, :account_number, :branch, :initial_deposit, :initial_deposit_words,
      :account_type, :term_deposit_type, :term_deposit_amount,
      :term_deposit_period_d, :term_deposit_period_m, :term_deposit_period_y,
      :term_interest_payable, :term_interest_credit_ac, :term_interest_payment,
      :rd_deposit_amount, :rd_deposit_period_m, :rd_deposit_period_y,
      :rd_sb_ac_no, :rd_credit_ac_no, :term_interest_rate, :rd_interest_rate, :customer_type,
      :app1_name, :app1_dob, :app1_aadhaar, :app1_sex, :app1_father_husband, :app1_relationship,
      :app2_name, :app2_dob, :app2_aadhaar, :app2_sex, :app2_father_husband, :app2_relationship,
      :app3_name, :app3_dob, :app3_aadhaar, :app3_sex, :app3_father_husband, :app3_relationship,
      :app1_perm_house, :app1_perm_village, :app1_perm_district, :app1_perm_pin,
      :app1_pres_house, :app1_pres_village, :app1_pres_district, :app1_pres_mobile,
      :app2_perm_house, :app2_perm_village, :app2_perm_district, :app2_perm_pin,
      :app2_pres_house, :app2_pres_village, :app2_pres_district, :app2_pres_mobile,
      :app3_perm_house, :app3_perm_village, :app3_perm_district, :app3_perm_pin,
      :app3_pres_house, :app3_pres_village, :app3_pres_district, :app3_pres_mobile,
      :mode_of_operation, :kyc_list1, :kyc_list2,
      :minor_guardian_name, :minor_guardian_relationship,
      :marital_status, :religion, :education, :occupation,
      :organisation_name, :nature_of_business, :profession,
      :annual_income, :asset_ownership, :preferred_investment, :loans_info, :insurance
    )
  end
end
