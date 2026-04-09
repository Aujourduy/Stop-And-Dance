class Admin::NotificationsController < Admin::ApplicationController
  include Pagy::Method

  def index
    scope = AdminNotification.recent

    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(category: params[:category]) if params[:category].present?

    if params[:q].present?
      params[:q].strip.split(/\s+/).each do |word|
        pattern = "%#{word}%"
        scope = scope.where("title ILIKE :p OR message ILIKE :p OR source ILIKE :p", p: pattern)
      end
    end

    @pagy, @notifications = pagy(scope, limit: 30)
    @non_lu_count = AdminNotification.non_lu.count

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def update
    notification = AdminNotification.find(params[:id])
    notification.update!(status: params[:status])
    redirect_to admin_notifications_path, notice: "Notification mise à jour"
  end

  def bulk_update
    ids = params[:ids] || []
    AdminNotification.where(id: ids).update_all(status: params[:status]) if ids.any?
    redirect_to admin_notifications_path, notice: "#{ids.size} notification(s) mise(s) à jour"
  end
end
