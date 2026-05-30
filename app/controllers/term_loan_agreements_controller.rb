class TermLoanAgreementsController < ApplicationController
  include EditPermission
  before_action :set_member
  before_action :set_term_loan_agreement, only: %i[show edit update destroy]
  before_action :set_loan_application
  def index
    base_scope = if current_user.head_office_user?
                   TermLoanAgreement.all
                 else
                   Current.branch.term_loan_agreements
                 end
    @q = base_scope.ransack(params[:q])
    @term_loan_agreements = @q.result(distinct: true)
  end
  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "member_form_#{@member.id}",
               template: "term_loan_agreements/show",
               layout: "pdf",
               margin: { top: 10, bottom: 20 },
               show_as_html: params.key?('debug'),
               footer: {
                  html: {
                    template: 'shared/pdf_header',
                    formats: [:html]
                  }
                }
      end
    end
  end
  def new
    @term_loan_agreement = @member.term_loan_agreements.new
  end
  def create
    @term_loan_agreement = @member.term_loan_agreements.new(term_loan_agreement_params)
    @term_loan_agreement.cooperative_branch_id = Current.branch.id
    @term_loan_agreement.loan_application_id = params[:loan_application_id]
    @term_loan_agreement.creator_id = current_user.id
    @term_loan_agreement.branch_manager = Current.branch.manager_name
    if @term_loan_agreement.save
      redirect_to member_loan_application_path(@member, @loan_application), notice: 'Term Loan Agreement was successfully created.'
    else
      render :new
    end
  end
  def edit; end
  def update
    if @term_loan_agreement.update(term_loan_agreement_params)
      redirect_to member_loan_application_path(@member, @loan_application), notice: 'Term Loan Agreement was successfully updated.'
    else
      render :edit
    end
  end
  def destroy
    @term_loan_agreement.destroy
    redirect_to member_term_loan_agreements_path(@member), notice: 'Term Loan Agreement was successfully deleted.'
  end
  private
  def set_member
    @member = Member.find(params[:member_id]) unless params[:member_id].blank?
  end
  def set_loan_application
    @loan_application = @member.loan_applications.find(params[:loan_application_id]) unless params[:loan_application_id].blank?
  end
  def set_term_loan_agreement
    @term_loan_agreement = TermLoanAgreement.find(params[:id])
  end
  def term_loan_agreement_params
    params.require(:term_loan_agreement).permit(
      :date, :month, :year, :loan_purpose, :application_date, :loan_amount,
      :loan_amount_words, :loan_amount_text, :sum_paid, :penalty_interest,
      :sanctioned_interest, :first_schedule, :document_date, :document_parties,
      :document_description, :document_security, :witness_date, :witness_month,
      :witness_year, :surety1, :surety2, :borrowers, :branch_manager_address, :second_schedule
    )
  end
  def find_resource_for_permission_check
    @term_loan_agreement
  end
  def resource_show_path_for(resource)
    member_loan_application_term_loan_agreement_path(resource.member, resource.loan_application, resource)
  end
end
