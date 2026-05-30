class MembersController < ApplicationController
  before_action :set_member, except: [:search_all]
  skip_before_action :authenticate_user!, only: [:search_all]
  skip_before_action :set_current_user, only: [:search_all]
  
  before_action :authorize_edit, only: [:edit, :update]

def index
  @q = Member.ransack(params[:q])
  @members = @q.result(distinct: true).includes(:memberships).page(params[:page]).per(50)
end

  def new
    @member = Current.branch.members.new
    @member.memberships.build
  end

  # GET /members/1/edit
  def edit
  end

  # POST /members
  def create
    @member = Current.branch.members.new(member_params)
    @member.cooperative_branch_id = Current.branch.id
    @member.creator_id = current_user.id
    if @member.save
      redirect_to @member, notice: 'Member was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /members/1
  def update
    if @member.update(member_params)
      redirect_to @member, notice: 'Member was successfully updated.'
    else
      render :edit
    end
  end

  def show
    @membership = @member.memberships.last
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "member_form_#{@member.id}",
               template: "members/show",
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

  def search
    query = params[:q].to_s.strip.downcase
    loan_application = Current.branch.loan_applications.find(params[:loan])

    # Collect all member IDs to exclude: current member and co-applicants
    excluded_ids = [params[:member].to_i]
    excluded_ids += loan_application.co_applicants.pluck(:id) if loan_application.co_applicants.any?

    # Perform the search
    members = Member
      .where("LOWER(name) LIKE ?", "%#{query}%")
      .where.not(id: excluded_ids)
      .limit(50)

    render json: members.map { |m| 
      {
        id: m.id,
        name: m.name,
        mobile_number: m.mobile_number,
        address: m.address,
        father_name: m.father_or_husband_name,
        age: m.age,
        profession: m.profession,
        employer: m.employer,
        experience: m.work_experience
      } 
    }
  end


  # DELETE /members/1
  def destroy
    @member.destroy
    redirect_to members_url, notice: 'Member was successfully deleted.'
  end

  def co_applicant_form
    @member = Member.find(params[:id])
    if @member.income_and_expenditures.blank?
       @member.income_and_expenditures.build(source: "Salary")
       @member.income_and_expenditures.build(source: "Profession")
       @member.income_and_expenditures.build(source: "Business")
       @member.income_and_expenditures.build(source: "Other")
    end
 
    @coapp = LoanApplicationCoApplicant.new(member: @member)
    render partial: 'loan_applications/co_applicant_fields', locals: { member: @member, coapp: @coapp}
  end

  private

  # Set @member for actions that require it
  def set_member
    #if(current_user.admin?)
      @member = Member.find(params["id"]) unless params["id"].blank?
    #else
      #@member = Member.where(id: params["id"]).where(cooperative_branch_id: Current.branch.id).last unless params["id"].blank?
    #end
  end

  # Staff users need approved edit request to edit members
  def authorize_edit
    return if current_user.super_admin? || current_user.section_head? || current_user.manager?

    # Staff users need to check for edit permission
    if current_user.staff?
      # Check if member belongs to user's branch
      unless @member.cooperative_branch_id == current_user.cooperative_branch_id
        redirect_to @member, alert: 'You can only edit members from your branch.'
        return
      end

      # Check if user has an approved edit request
      unless EditRequest.has_approved_request?('Member', @member.id, current_user.id)
        redirect_to @member, alert: 'You need approval to edit this member. Please submit an edit request.'
        return
      end
    end
  end

  # Strong params to allow nested attributes for memberships
  def member_params
    permitted_params = []
    permitted_membership_params = [:id, :_destroy]

    # Member fields (up to office-note section) - only for staff and manager
    if current_user.staff? || current_user.manager?
      permitted_params.concat([
        :name, :father_or_husband_name, :father_or_husband, :mobile_number, :aadhaar_number, :voter_id, :pan_card, :driving_license, :age, :education, :occupation, :religion, :caste_category, :address_a_building, :address_b_building, :address_a_village, :address_b_village, :address_a_district, :address_b_district, :address_a_pincode, :address_b_pincode, :religion_other
      ])
      permitted_membership_params.concat([
        :number_of_shares, :amount, :nominee_name, :nominee_address, :nominee_relationship, :other_particulars, :place, :signed_date, :nominee_phone
      ])
    end

    # Office fields (after office-note section) - only for section_head, super_admin
    if current_user.section_head? || current_user.super_admin?
      permitted_params << :member_no
      permitted_membership_params.concat([:md_sign_place, :md_signed_date, :resolution_no, :resolution_date])
    end

    params.require(:member).permit(
      *permitted_params,
      memberships_attributes: permitted_membership_params
    )
  end

def search_all
  members = Member.order(:name).limit(500).pluck(:id, :name, :father_or_husband_name)
  render json: members.map { |id, name, foh| { id: id, name: name, father_or_husband_name: foh } }
end
end
 
