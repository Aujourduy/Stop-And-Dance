# Solid Queue Configuration
# https://github.com/basecamp/solid_queue

Rails.application.configure do
  # Queue names and priorities
  config.active_job.queue_name_prefix = "graces"

  # Queue priorities (default: 0, low: -10, high: 10)
  config.active_job.queue_adapter = :solid_queue

  # Development: inline job processing for faster development
  if Rails.env.development?
    config.active_job.queue_adapter = :inline
  end
end

# Queue definitions:
# - default: General application jobs (priority: 0)
# - scraping: Web scraping jobs (priority: 0)
# - notifications: Email notifications (priority: 10 - high)
#
# Recurring tasks configured in config/recurring.yml (Story 3.6)
