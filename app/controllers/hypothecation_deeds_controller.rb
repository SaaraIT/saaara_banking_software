class HypothecationDeedsController < ApplicationController
  include EditPermission

  before_action :set_loan_application
  before_action :set_member
  before_action :set_hypothecation_deed, only: %i[show edit update destroy]

  def index
    base_scope = if current_user.head_office_user?
                   HypothecationDeed.all
                 else
                   Current.branch.hypothecation_deeds
                 end
    @q = base_scope.ransack(params[:q])
    @hypothecation_deeds = @q.result(distinct: true).includes(:member, loan_application: :loan_type)
  end

  def new
    @hypothecation_deed = @member.hypothecation_deeds.new
  end

  def create
    @hypothecation_deed = @member.hypothecation_deeds.new(hypothecation_deed_params)
    @hypothecation_deed.loan_application_id = params["loan_application_id"]
    @hypothecation_deed.cooperative_branch_id = Current.branch.id
    @hypothecation_deed.creator_id = current_user.id
    if @hypothecation_deed.save
      redirect_to member_loan_application_path(@member, @loan_application), notice: "HypothecationDeed created successfully."
    else

      render :new
    end
  end

  def show   
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "member_form_#{@member.id}",
               template: "hypothecation_deeds/show",
               layout: "pdf",
               margin: { top: 10, bottom: 10 }, 
               footer: {
                  html: {
                    template: 'shared/pdf_header',
                    formats: [:html]
                  }
                },
               show_as_html: params.key?('debug')
      end
    end
  end

  def edit; end

  def update
    if @hypothecation_deed.update(hypothecation_deed_params)
      redirect_to member_loan_application_path(@member, @loan_application), notice: "HypothecationDeed updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @hypothecation_deed.destroy
    redirect_to member_path(@member), notice: "HypothecationDeed deleted successfully."
  end

  private

  def set_member
    @member = @loan_application.try(:member)
  end

  def set_hypothecation_deed
    @hypothecation_deed = @loan_application.hypothecation_deeds.find(params[:id])
  end
  
  def set_loan_application
    return if params["loan_application_id"].blank?
    @loan_application = if current_user.head_office_user?
                          LoanApplication.find(params["loan_application_id"])
                        else
                          Current.branch.loan_applications.find(params["loan_application_id"])
                        end
  end

  def hypothecation_deed_params
    params.require(:hypothecation_deed).permit(:amount, :place, :date, :borrower_name, :witness1, :witness2, :from, :promissory_date, :loan_amount, :loan_details,  :sum, :interest, :promissory_not_date, :promissory_not_amount, :account_no, :account_name, :day, :month, :year, :industry_location, :taluk, :district, :agreement_date, :term_loan_amount, :working_capital_amount, :maximum_limit, :interest_rate, :moratorium_period, :installment_amount, :first_installment_date, :subsequent_installment_date, :signed_day, :signed_month, :signed_year)
  end

  def find_resource_for_permission_check
    @hypothecation_deed
  end

  def resource_show_path_for(resource)
    member_loan_application_hypothecation_deed_path(resource.member, resource.loan_application, resource)
  end
end
