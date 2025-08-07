class PlansController < ApplicationController
  before_action :set_plan, only: %i[ show edit update destroy ]

  # GET /plans or /plans.json
  def index
    @plans = Plan.all
  end

  # GET /plans/1 or /plans/1.json
  def show
  end

  # GET /plans/new
  def new
    @plan = Plan.new
  end

  # GET /plans/1/edit_workouts
  def edit_workouts
    @activities = @plan.activities.order(:start_date_local)
    
    # If no activities exist for a custom plan, create a blank schedule
    if @activities.empty? && @plan.custom?
      create_blank_schedule
      @activities = @plan.activities.order(:start_date_local)
    end
  end

  # POST /plans/1/create_blank_schedule
  def create_blank_schedule
    return unless @plan.custom?
    
    start_date = (@plan.race_date - @plan.length.weeks).beginning_of_week(:monday)
    
    (@plan.length * 7).times do |day_index|
      Activity.create!(
        plan_id: @plan.id,
        distance: 0.0,
        description: "Rest day",
        start_date_local: start_date + day_index.days
      )
    end
    
    redirect_to edit_workouts_plan_path(@plan), notice: "Blank workout schedule created. You can now customize each day."
  end

  # PATCH /plans/1/update_workouts
  def update_workouts
    activities_params = params.require(:activities)
    
    activities_params.each do |id, activity_data|
      activity = Activity.find(id)
      activity.update(
        distance: activity_data[:distance],
        description: activity_data[:description]
      )
    end
    
    redirect_to @plan, notice: "Workouts were successfully updated."
  end

  # GET /plans/1/edit
  def edit
  end

  # POST /plans or /plans.json
  def create
    @plan = Plan.new(plan_params)

    respond_to do |format|
      if @plan.save
        success_message = if @plan.custom?
          "Custom plan was successfully created. #{@plan.photos.attached? ? 'Photos are being processed to extract workout details.' : 'You can now edit your workouts.'}"
        else
          "Plan was successfully created."
        end
        
        format.html { redirect_to @plan, notice: success_message }
        format.json { render :show, status: :created, location: @plan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plans/1 or /plans/1.json
  def update
    respond_to do |format|
      if @plan.update(plan_params)
        format.html { redirect_to @plan, notice: "Plan was successfully updated." }
        format.json { render :show, status: :ok, location: @plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plans/1 or /plans/1.json
  def destroy
    @plan.destroy!

    respond_to do |format|
      format.html { redirect_to plans_path, status: :see_other, notice: "Plan was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plan
      @plan = Plan.find(params.require(:id))
    end

    # Only allow a list of trusted parameters through.
    def plan_params
      params.require(:plan).permit(:length, :race_date, :plan_type, photos: [])
    end
end
