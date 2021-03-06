class WelcomeController < ApplicationController
  def index
    (@filterrific = initialize_filterrific(
      Schedule,
      params[:filterrific],
      select_options: {
        by_departure: Schedule.options("departure"),
        by_destination: Schedule.options("destination"),
        by_date: Schedule.options("date"),
        sorted_by: Schedule.options_for_sorted_by
      },
    )) || return
    @schedule = @filterrific.find.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    if Current.user.nil? || Current.user.name != "ADMIN"
      redirect_to root_path
    else
      @schedule = Schedule.new
    end
  end

  def create
    @schedule = Schedule.new(sched_params)
    @errs = []
    if valid_date?(params[:schedule][:date]) && valid_time?(params[:schedule][:time])
      if @schedule.save
        Seating.make
        flash[:success] = 'Schedule created'
        redirect_to root_path
      else
        flash[:danger] = @schedule.errors.full_messages
        redirect_to add_schedule_path
      end
    elsif !(valid_time?(params[:schedule][:time]))
      flash[:danger] = 'Invalid time'
      redirect_to add_schedule_path
    else
      flash[:danger] = 'Invalid date'
      redirect_to add_schedule_path
    end
  end

  def show
    if Current.user.nil? || Current.user.name != "ADMIN"
      redirect_to root_path
    else
      @bookings = Booking.where(schedule_id: params[:book_id])
      @seatings = Seating.where(schedule_id: params[:book_id])
    end
  end

  private

  def valid_time?(str)
    !!(str =~ /\A([0-1][0-9]|[2][0-3]):([0-5][0-9])\z/)
  end

  def valid_date?(str)
    Date.parse(str) rescue false
    str.length == 10
  end

  def sched_params
    params.require(:schedule).permit(:id, :departure, :destination, :date, :time, :seats_available, :price)
  end
end
