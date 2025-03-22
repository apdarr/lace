class ActivitiesController < ApplicationController
  before_action :set_activity, only: %i[ show edit update destroy ]

  # GET /activities or /activities.json
  def index
    if params[:query].present?
      embedding = CreateEmbeddingsJob.perform_now(params[:query])
      @activities = Activity.nearest_neighbors(:embedding, embedding, distance: :cosine)
    else
      @activities = Activity.all
    end
    @activities = @activities.page(params[:page]).per(9)
  end

  # GET /activities/1 or /activities/1.json
  def show
    @activity = Activity.find(params[:id])
    @nearest_activities = @activity.nearest_neighbors(:embedding, distance: "euclidean").first(5)
  end

  # GET /activities/new
  def new
    @activity = Activity.new
  end

  # GET /activities/1/edit
  def edit
  end

  # POST /activities or /activities.json
  def create
    ### 🧪 Reenable to get imports working again 🧪 ###

    # AllActivityJob.perform_later

    ### 🧪 Reenable to get imports working again 🧪 ###

    flash[:notice] = "Activity has been enqueued for processing."
    # @activity = Activity.new(activity_params)

    # respond_to do |format|
    #   if @activity.save
    #     format.html { redirect_to @activity, notice: "Activity was successfully created." }
    #     format.json { render :show, status: :created, location: @activity }
    #   else
    #     format.html { render :new, status: :unprocessable_entity }
    #     format.json { render json: @activity.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /activities/1 or /activities/1.json
  def update
    respond_to do |format|
      if @activity.update(activity_params)
        format.html { redirect_to @activity, notice: "Activity was successfully updated." }
        format.json { render :show, status: :ok, location: @activity }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @activity.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /activities/1 or /activities/1.json
  def destroy
    @activity.destroy!

    respond_to do |format|
      format.html { redirect_to activities_path, status: :see_other, notice: "Activity was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_activity
      @activity = Activity.find(params.require(:id))
    end

    # Only allow a list of trusted parameters through.
    def activity_params
      params.require(:activity).permit(:distance, :elapsed_time, :activity_type, :kudos_count, :average_heart_rate, :max_heart_rate, :description)
    end
end
