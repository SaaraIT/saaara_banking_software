class ShgTermLoanAgreementsController < ApplicationController
  include EditPermission

  before_action :set_shg_loan_application
  before_action :set_term_loan_agreement, only: %i[show edit update destroy]


  def index
    base_scope = if current_user.head_office_user? || Current.branch.nil?
                   ShgTermLoanAgreement.all
                 else
                   Current.branch.shg_term_loan_agreements
                 end
    @q = base_scope.ransack(params[:q])
    @term_loan_agreements = @q.result(distinct: true)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "shg_loan_form_#{@loan_application.id}",
               template: "shg_term_loan_agreements/show",
               layout: "pdf",
                margin: { top: 10, bottom: 10 }, 
               show_as_html: params.key?('debug'),
               footer: {
                  html: {
                    template: 'shared/pdf_header',
                    formats: [:html]
                  }
                },
               margin: {
                 bottom: 20 # specify the margin in mm
               } 
      end
    end
  end

  def new
    @term_loan_agreement = @loan_application.build_shg_term_loan_agreement
  end

  def create
    @term_loan_agreement = @loan_application.build_shg_term_loan_agreement(term_loan_agreement_params)
    @term_loan_agreement.cooperative_branch_id = @loan_application.cooperative_branch_id
    @term_loan_agreement.self_help_group_id = @loan_application.self_help_group_id
    @term_loan_agreement.creator_id = current_user.id
    if @term_loan_agreement.save
      redirect_to shg_loan_application_path(@loan_application), notice: 'Term Loan Agreement was successfully created.'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @term_loan_agreement.update(term_loan_agreement_params)
      redirect_to shg_loan_application_path(@loan_application), notice: 'Term Loan Agreement was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @term_loan_agreement.destroy
    redirect_to shg_loan_application_path(@loan_application), notice: 'Term Loan Agreement was successfully deleted.'
  end

  private


  def set_shg_loan_application
    return if params[:shg_loan_application_id].blank?
    @loan_application = if current_user.head_office_user? || Current.branch.nil?
                          ShgLoanApplication.find(params[:shg_loan_application_id])
                        else
                          Current.branch.shg_loan_applications.find(params[:shg_loan_application_id])
                        end
  end

  def set_term_loan_agreement
    @term_loan_agreement = @loan_application.shg_term_loan_agreement
  end

  def term_loan_agreement_params
    params.require(:shg_term_loan_agreement).permit(
      :date, :month, :year, :loan_purpose, :application_date, :loan_amount,
      :loan_amount_words, :loan_amount_text, :sum_paid, :penalty_interest,
      :sanctioned_interest, :first_schedule, :document_date, :document_parties,
      :document_description, :document_security, :witness_date, :witness_month,
      :witness_year, :surety1, :surety2, :borrowers, :branch_manager,:branch_manager_address, :second_schedule
    )
  end

  def find_resource_for_permission_check
    @term_loan_agreement
  end
end
