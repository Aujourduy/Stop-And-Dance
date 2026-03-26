class Admin::ApplicationController < ActionController::Base
  http_basic_authenticate_with(
    name: ENV.fetch('ADMIN_USERNAME', 'admin'),
    password: ENV.fetch('ADMIN_PASSWORD', 'changeme')
  )

  before_action :set_admin_meta_tags
  layout 'admin'

  private

  def set_admin_meta_tags
    set_meta_tags(robots: 'noindex, nofollow')
  end
end
