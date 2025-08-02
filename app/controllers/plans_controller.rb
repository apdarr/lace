class PlansController < ApplicationController
  before_action :set_plan, only: %i[ show edit update destroy process_photos ]

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

  # GET /plans/1/edit
  def edit
    # If this plan has photos and no activities yet, try to process the photos
    if @plan.custom_creation? && @plan.photos.attached? && Activity.where(plan_id: @plan.id).empty?
      process_photos_for_plan
    end
  end

  # POST /plans or /plans.json
  def create
    @plan = Plan.new(plan_params)

    respond_to do |format|
      if @plan.save
        # If this is a custom creation, redirect to edit to allow workout customization
        if @plan.custom_creation?
          format.html { redirect_to edit_plan_path(@plan), notice: "Plan created! Now customize your workouts below." }
        else
          format.html { redirect_to @plan, notice: "Plan was successfully created." }
        end
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

  # POST /plans/1/process_photos
  def process_photos
    if @plan.photos.attached?
      parsed_workouts = @plan.process_uploaded_photos
      if parsed_workouts.any?
        @plan.create_activities_from_parsed_data(parsed_workouts)
        redirect_to edit_plan_path(@plan), notice: "Successfully processed #{@plan.photos.count} photo(s) and created workouts!"
      else
        redirect_to edit_plan_path(@plan), alert: "Unable to extract workout data from the uploaded photos."
      end
    else
      redirect_to edit_plan_path(@plan), alert: "No photos to process."
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plan
      @plan = Plan.find(params.require(:id))
    end

    # Only allow a list of trusted parameters through.
    def plan_params
      params.require(:plan).permit(:length, :race_date, :custom_creation, photos: [])
    end

    def process_photos_for_plan
      if @plan.photos.attached?
        parsed_workouts = @plan.process_uploaded_photos
        if parsed_workouts.any?
          @plan.create_activities_from_parsed_data(parsed_workouts)
          flash.now[:notice] = "Successfully processed #{@plan.photos.count} photo(s) and created initial workouts! You can edit them below."
        end
      end
    end
end
