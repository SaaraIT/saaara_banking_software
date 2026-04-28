class ShgLoanProNotesController < ApplicationController
  include EditPermission

  before_action :set_shg_loan_application
  before_action :set_shg_pro_note, only: %i[show edit update destroy]


  def index
    base_scope = if current_user.head_office_user?
                   ShgLoanProNote.all
                 else
                   Current.branch.shg_pro_notes
                 end
    @q = base_scope.ransack(params[:q])
    @shg_pro_notes = @q.result(distinct: true)
  end

  def new
    @shg_pro_note = ShgLoanProNote.new(shg_loan_application_id: @shg_loan_application.id)
  end

  def create
    @shg_pro_note = ShgLoanProNote.new(shg_pro_note_params)
    @shg_pro_note.shg_loan_application_id = @shg_loan_application.id
    @shg_pro_note.cooperative_branch_id = @shg_loan_application.cooperative_branch_id
    @shg_pro_note.shg_loan_application_id = params["shg_loan_application_id"]
    @shg_pro_note.creator_id = current_user.id
    if @shg_pro_note.save
      redirect_to self_help_group_shg_loan_application_path(@shg_loan_application.self_help_group, @shg_loan_application), notice: "ProNote created successfully."
    else
      render :new
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "shg_loan_pro_note_form_#{@shg_pro_note.id}",
               template: "shg_loan_pro_notes/show",
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
    if @shg_pro_note.update(shg_pro_note_params)
      redirect_to self_help_group_shg_loan_application_path(@shg_loan_application.self_help_group, @shg_loan_application), notice: "ProNote updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @shg_pro_note.destroy
    redirect_to shg_member_path(@shg_member), notice: "ProNote deleted successfully."
  end

  private
 
  def set_shg_pro_note
    @shg_pro_note = ShgLoanProNote.where(id: params[:id]).where(shg_loan_application_id: @shg_loan_application.id).first
  end

  def shg_pro_note_params
    params.require(:shg_loan_pro_note).permit(:amount, :place, :date,  :promissory_date, :loan_amount, :loan_details,  :sum, :interest, :promissory_not_date, :promissory_not_amount, :account_no, :account_name, :delivery_date, :loan, :loan_delivery_date, :penal_rate)
  end

  def set_shg_loan_application
    return if params["shg_loan_application_id"].blank?
    @shg_loan_application = if current_user.head_office_user?
                              ShgLoanApplication.find(params["shg_loan_application_id"])
                            else
                              Current.branch.shg_loan_applications.find(params["shg_loan_application_id"])
                            end
  end

  def find_resource_for_permission_check
    @shg_pro_note
  end
end
