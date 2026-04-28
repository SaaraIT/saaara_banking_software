class ShgDemandPromissoryNotesController < ApplicationController
  include EditPermission

  before_action :set_loan_application
  before_action :set_demand_promissory_note, only: [:show, :edit, :update, :destroy]


  def index
    base_scope = if current_user.head_office_user?
                   ShgDemandPromissoryNote.all
                 else
                   Current.branch.shg_demand_promissory_notes
                 end
    @q = base_scope.ransack(params[:q])
    @demand_promissory_notes = @q.result(distinct: true)
  end

  def show
    @member = Member.find(params[:id])
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "loan_application_#{@loan_application.id}",
               template: "shg_demand_promissory_notes/show",
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

  def new
    @demand_promissory_note = @loan_application.build_shg_demand_promissory_note
  end

  def create
    @demand_promissory_note = @loan_application.build_shg_demand_promissory_note(shg_demand_promissory_note_params)
    @demand_promissory_note.cooperative_branch_id = @loan_application.cooperative_branch_id
    @demand_promissory_note.creator_id = current_user.id

    if @demand_promissory_note.save
      redirect_to shg_loan_application_path(@loan_application), notice: "Demand Promissory Note created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @demand_promissory_note.update(shg_demand_promissory_note_update_params)
      redirect_to shg_loan_application_path(@loan_application), notice: "Demand Promissory Note updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @demand_promissory_note.destroy
    redirect_to shg_loan_application_path(@loan_application), notice: "Demand Promissory Note deleted successfully."
  end

  private
 
  def set_demand_promissory_note
    @demand_promissory_note = @loan_application.shg_demand_promissory_note
  end

  def set_loan_application
    return if params["shg_loan_application_id"].blank?
    @loan_application = if current_user.head_office_user?
                          ShgLoanApplication.find(params["shg_loan_application_id"])
                        else
                          Current.branch.shg_loan_applications.find(params["shg_loan_application_id"])
                        end
  end
  
  def shg_demand_promissory_note_params
    params.require(:shg_demand_promissory_note).permit(:branch, :loan_no, :amount, :day, :month, :year, :borrower_name, :surety1_name, :surety2_name, :interest_rate, :penal_rate, :witness1, :witness2, :sum, :sum_in_words)
  end

  def shg_demand_promissory_note_update_params
    params.require(:shg_demand_promissory_note).permit(:loan_no)
  end

  def find_resource_for_permission_check
    @demand_promissory_note
  end
end

