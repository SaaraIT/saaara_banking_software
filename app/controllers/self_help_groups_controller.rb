class SelfHelpGroupsController < ApplicationController
  before_action :set_self_help_group, only: %i[show edit update destroy]

  def index
    @self_help_groups = SelfHelpGroup.includes(:shg_members)
    @self_help_groups = @self_help_groups.where("LOWER(name) LIKE ?", "%#{params[:q].to_s.strip.downcase}%") if params[:q].present?
  end

  def show; end

  def new
    @self_help_group = SelfHelpGroup.new
    20.times do |i|
      @self_help_group.shg_members.build(position: i + 1)
    end
  end

  def create
    @self_help_group = SelfHelpGroup.new(self_help_group_params)
    @self_help_group.cooperative_branch =  Current.branch
    if @self_help_group.save
      redirect_to @self_help_group, notice: 'Self Help Group was successfully created.'
    else
      render :new
    end
  end

  def edit
    # Ensure at least one member exists for editing
    #@self_help_group.shg_members.build if @self_help_group.shg_members.empty?
    existing_positions = @self_help_group.shg_members.pluck(:position)
    max_position = existing_positions.compact.max || 0

    missing = 20 - @self_help_group.shg_members.size

    missing.times do |i|
      @self_help_group.shg_members.build(position: max_position + i + 1)
    end

    #(20 - @self_help_group.shg_members.count).times { @self_help_group.shg_members.build }
  end

  def update
    if @self_help_group.update(self_help_group_params)
      redirect_to @self_help_group, notice: 'Self Help Group was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @self_help_group.destroy
    redirect_to self_help_groups_url, notice: 'Self Help Group was successfully destroyed.'
  end

  private

  def set_self_help_group
    @self_help_group = SelfHelpGroup.find(params[:id])
  end

  def self_help_group_params
    params.require(:self_help_group).permit(
      :name, :address, :cooperative_branch_id,
      shg_members_attributes: [
        :id, :name, :address, :aadhar_number, :mobile, :signature,
        :age, :husband_or_father_name, :door_number, :village, :taluk,
        :pin_code, :pan_number, :occupation, :income, :membership_no, :position, :_destroy
      ]
    )
  end
end
