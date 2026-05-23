class LoanApplicationsController < ApplicationController
  include LoanEditPermission

  before_action :set_member, only: %i[show edit new index update]
  prepend_before_action :set_loan_application, only: %i[show edit update destroy update_co_obligants]

  def index
    if(current_user.super_admin? || current_user.section_head?)
      @q = LoanApplication.ransack(params[:q])
    else
      @q = Current.branch.loan_applications.ransack(params[:q])
    end

    @loan_applications = @q.result(distinct: true)
  end

  def new
    @loan_application =  LoanApplication.new
    
    if @member.blank?
      @member = @loan_application.build_member 
    else
      @loan_application.member = @member
    end

    build_attributes
   
    if params[:g].present?
      guarantor_ids = params[:g].split(",").map(&:to_i)
      guarantor_ids.each.with_index do |id, index|
        @loan_application.co_obligants.build(member_id: id, position: index=1) 
      end
    else
      2.times { @loan_application.co_obligants.build } # Default to 2 empty co-obligants
    end
 
  end

  def create
    @member = Member.find(params[:loan_application][:member_attributes][:id])

    # Update nested associations of Member
    @member.assign_attributes(member_nested_params)

    @loan_application = LoanApplication.new(loan_application_params)
    @loan_application.member = @member
    @loan_application.cooperative_branch =  Current.branch
    @loan_application.creator_id = current_user.id

    if @loan_application.save
      create_or_update_coapplicant_member_data #for some reason nested_attributes are not working. so explicitly assigning
      redirect_to [@member, @loan_application], notice: "Loan application created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_attributes
  end

  def update
    if @loan_application.update(loan_application_params)
      @member.assign_attributes(member_nested_params)
      @member.save
      create_or_update_coapplicant_member_data #for some reason nested_attributes are not working. so explicitly assigning
      redirect_to [@member, @loan_application], notice: "Loan Application updated successfully."
    else
      render :edit
    end
  end

  def update_co_obligants
    guarantor_ids = params[:guarantor_ids].map(&:to_i)
    # Delete ALL existing guarantor_undertakings and co_obligants first
    @loan_application.guarantor_undertakings.destroy_all
    @loan_application.co_obligants.destroy_all
    # Create new ones
    guarantor_ids.each_with_index do |id, index|
      @loan_application.guarantor_undertakings.create(
        guarantor_id: id,
        member_id: @loan_application.member_id,
        cooperative_branch_id: @loan_application.cooperative_branch_id,
        creator_id: current_user.id
      )
      @loan_application.co_obligants.create(
        member_id: id,
        position: index + 1
      )
    end
    render json: { success: true }
  end

  def show
    @guarantor_undertakings = @loan_application.guarantor_undertakings.includes(:guarantor)

    respond_to do |format|
      format.html
      format.pdf do
       render pdf: "loan_application_form_#{@loan_application.id}",
        template: "loan_applications/show",
        layout: "pdf",
        margin: { top: 5, bottom: 8 }, 
        footer: {
          html: {
            template: 'shared/pdf_header',
            formats: [:html]
          }
        },
        enable_local_file_access: true,
        show_as_html: params.key?('debug')

      end
    end
  end

  def destroy
    @loan_application.destroy
    redirect_to @member, notice: "Loan Application deleted."
  end

  private

  def set_member
    return if params["member_id"].blank?
    
    #if(current_user.admin?)
      @member = Member.find(params["member_id"])
    #else
      #@member = Member.where(id: params["member_id"]).where(cooperative_branch_id: Current.branch.id).last
    #end
  end

  def set_loan_application
    #if(current_user.admin?)
      @loan_application = LoanApplication.find(params["id"]) unless params["id"].blank?
    #else
      #@loan_application = LoanApplication.where(id: params["id"]).where(member_id: @member.id).last unless params["id"].blank?
    #end
  end

  def find_loan_for_permission_check
    @loan_application
  end

  def build_attributes
    6.times { @member.family_members.build } if @member.family_members.blank?
      
    if @member.deposits_and_shares.blank?
       @member.deposits_and_shares.build(particular: "S.B. A/C No.") 
       @member.deposits_and_shares.build(particular: "Term Deposit") 
       @member.deposits_and_shares.build(particular: "Share Capital", account_no: @member.member_no)
       @member.deposits_and_shares.build(particular: "Others")
    end

    if @member.income_and_expenditures.blank?
      @member.income_and_expenditures.build(source: "Salary")
      @member.income_and_expenditures.build(source: "Profession")
      @member.income_and_expenditures.build(source: "Business")
      @member.income_and_expenditures.build(source: "Other")
    end

    
    if @member.existing_loan_liabilities.blank?
      ["In Sahakari", "Co-op Bank Societies", "Other Bank"].each do |category|
        @member.existing_loan_liabilities.build(category: category) if @member.existing_loan_liabilities.none? { |l| l.category == category }
      end
    end

    @member.build_business_detail if @member.business_detail.blank?
    @member.build_insurance_policy if @member.insurance_policy.blank?
    @member.build_vehicle if @member.vehicle.blank?
    @member.build_deposit if @member.deposit.blank?
    @member.build_gold_ornament if @member.gold_ornament.blank?
    @member.build_immovable_property if @member.immovable_property.blank?
    @member.build_indirect_liability if @member.indirect_liability.blank?
    @member.build_tax_detail if @member.tax_detail.blank?
  end
 
  # app/controllers/loan_applications_controller.rb
  def create_or_update_coapplicant_member_data
    coapp_attrs = params.dig(:loan_application, :loan_application_co_applicants_attributes) || {}
    return if coapp_attrs.blank?
    
    # Get IDs of existing co-applicant members
    existing_member_ids = @loan_application.co_applicants.pluck(:id)
    processed_member_ids = []

    coapp_attrs.each do |_, attrs|
      member_id = attrs[:member_id].to_i
      member_data = attrs[:member_attributes] || {}
      next if member_id.zero? || member_data.blank?

      # Skip duplicates in current batch
      next if processed_member_ids.include?(member_id)
      processed_member_ids << member_id

      member = Member.find_by(id: member_id)
      next unless member

      co_applicant = @loan_application.loan_application_co_applicants.find_or_create_by(member_id: member_id)
      co_applicant.business_details = attrs["business_details"]
      co_applicant.deatils_of_sahakari_loan = attrs["deatils_of_sahakari_loan"]
      co_applicant.details_of_immovable_property = attrs["details_of_immovable_property"]
      co_applicant.details_of_movable_property = attrs["details_of_movable_property"]
      co_applicant.date_signed = attrs["date_signed"]
      co_applicant.place_signed = attrs["place_signed"]

      co_applicant.save
       # Process income/expenditure data
      process_member_financials(member, member_data, @loan_application.id)
    end

    # Remove unselected co-applicants
    removed_ids = existing_member_ids - processed_member_ids
    @loan_application.loan_application_co_applicants.where(member_id: removed_ids).destroy_all if removed_ids.any?
  end
   

  def process_member_financials(member, member_data, loan_app_id)
    member_data["income_and_expenditures_attributes"].each do |entry|
      record = member.income_and_expenditures.find_or_initialize_by(
        source: entry["source"]
      )

      record.assign_attributes(
          income: entry["income"],
          expenditure: entry["expenditure"]
      )
      record.save!
    end    
  end

  def loan_application_params
    params.require(:loan_application).permit(
      :member_id,
      :loan_type_id,
      :loan_purpose_id,
      :r_no,
      :application_date,
      :estimated_cost,
      :declaration_date,
      :declaration_place,
      :branch_incharge_report,
      :branch_manager_report,
      :purpose_bm,
      :loan_amount_bm,
      :sanction_order_date,
      :term_bm,
      :security_bm,
      :date_bm,
      :place_bm,
      :head_office_report,
      :date_ho,
      :place_ho,
      :sanction_amount,
      :sanction_amount_words,
      :sanction_order_no,
      :"sanction_order_date(1i)",
      :"sanction_order_date(2i)",
      :"sanction_order_date(3i)",
      :date_bo,
      :limit_bo,
      :resolution_no_bo,
      :loan_disbursement_date,
      :account_no,
      :loan_term,
      :loan_amount_disbursed,
      :rate_of_interest,
      :date_disbursement,
      :place_disbursement,
      :inspection_review,
      :date_inspection,
      :place_inspection,
      :loan_amount,
      # Co-obligants
      co_obligants_attributes: [
        :id,
        :member_id,
        :business_details,
        :tax_assessee,
        :gst_holder,
        :gst_number,
        :loan_details,
        :immovable_property,
        :movable_property,
        :guaranteed_for,
        :declaration_date,
        :declaration_place,
        :position,
        :_destroy
      ]
    )
  end

  def member_nested_params
    params.require(:loan_application).require(:member_attributes).permit(
       :id,
        :name,
        :father_or_husband_name,
        :age,
        :address_a_building,
        :address_a_village,
        :address_a_district,
        :address_a_pincode,
        :mobile_number,
        :aadhaar_number,
        :pan_card,
        deposits_and_shares: [:particular, :account_no, :balance_on_date],

        family_members_attributes: [:id, :name, :relationship, :annual_income, :income_source, :_destroy],
        deposits_and_shares_attributes: [:id, :particular, :account_no, :balance_on_date, :_destroy],
        income_and_expenditures_attributes: [:id, :source, :income, :expenditure],
        existing_loan_liabilities_attributes: [:id, :category, :date_of_loan, :purpose, :loan_amount, :balance_outstanding, :overdue_amount, :_destroy],
        business_detail_attributes: [:id, :business_name, :constitution, :relation_with_firm, :capital_employed, :bankers_to_business, :liability_to_banks, :annual_income, :other_bank_dealings],
        insurance_policy_attributes: [:id, :amount_assured, :policy_period, :paid_up_value, :surrender_value, :policy_name, :maturity_date],
        vehicle_attributes: [:id, :vehicle_type, :make_model, :registration_no, :purchase_cost, :insurance_company, :valid_upto, :market_value],
        deposit_attributes: [:id, :bank_name, :amount, :maturity_date, :maturity_value],
        gold_ornament_attributes: [:id, :description, :gross_weight, :market_value],
        immovable_property_attributes: [
          :id,
          :description, :property_number, :extent, :location, :market_value,
          :houses_owned, :house_cts_vpc_trc_no, :house_extent, :house_location, :house_market_value,
          :non_agri_land, :land_survey_no, :land_area, :land_location, :land_market_value,
          :existing_liabilities, :annual_income
        ],
        indirect_liability_attributes: [:id, :co_obligant_guarantor],
        tax_detail_attributes: [:id, :income_tax_assessee, :gst_registration_holder, :gst_number]
    )
  end
end
