class ApplicationJob < ActiveJob::Base
  # Retry strategy: exponential backoff for standard errors
  # Attempts: 3 (5s, 25s, 125s)
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
