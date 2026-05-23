class ShgAccountsController < ApplicationController
  before_action :set_shg
  before_action :set_shg_account, only: [:show, :edit, :update]

  def index
    @shg_accounts = @shg.shg_accounts.order(created_at: :desc)
  end

  def new
    @shg_account = ShgAccount.new
    @shg_account.shg_name    = @shg.name
    @shg_account.shg_address = @shg.address
    @shg_account.branch      = Current.branch.try(:name)
    @shg_account.date        = Date.today
  end

  def create
    @shg_account = ShgAccount.new(shg_account_params)
    @shg_account.self_help_group_id = @shg.id
    if @shg_account.save
      redirect_to "/self_help_groups/#{@shg.id}", notice: "SHG Account created successfully."
    else
      render :new
    end
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "shg_account_#{@shg_account.id}",
               page_size: "A4",
               layout: "pdf",
               encoding: "UTF-8"
      end
    end
  end

  def edit
  end

  def update
    if @shg_account.update(shg_account_params)
      redirect_to self_help_group_shg_account_path(@shg, @shg_account), notice: "SHG Account updated successfully."
    else
      render :edit
    end
  end

  private

  def set_shg
    @shg = SelfHelpGroup.find(params[:self_help_group_id])
  end

  def set_shg_account
    @shg_account = ShgAccount.find(params[:id])
  end

  def shg_account_params
    params.require(:shg_account).permit(
      :branch, :date, :account_number, :gender_code,
      :shg_name, :date_of_formation, :number_of_members, :shg_address,
      :president_name, :president_age, :president_designation,
      :president_address, :president_mobile, :president_kyc,
      :secretary_name, :secretary_age, :secretary_designation,
      :secretary_address, :secretary_mobile, :secretary_kyc,
      :officer_name, :account_opened_on
    )
  end
end
