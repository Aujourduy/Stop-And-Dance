class Admin::ChangeLogsController < Admin::ApplicationController
  include Pagy::Method

  def index
    @pagy, @change_logs = pagy(
      ChangeLog.includes(:scraped_url).order(created_at: :desc),
      limit: 50
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @change_log = ChangeLog.find(params[:id])
  end
end
