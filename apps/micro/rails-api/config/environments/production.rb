# Production settings for the benchmark app.
#
# The generated production.rb assumes a TLS-terminating proxy in front of the
# app and silences `/up` logging. The benchmark sends plain HTTP straight to
# the container and measures the request path only, so this file keeps the
# defaults that matter (eager load, no reloading, no error pages) and turns off
# the two that would otherwise change what is measured:
#
#   - force_ssl / assume_ssl: otherwise every request is a 301 redirect.
#   - silence_healthcheck_path: `/up` must go through the same logging path as
#     any other route, or the comparison would be a comparison of two children.
#
# RAILS_LOG_LEVEL=fatal reproduces "logging off" for the second profile.
Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.force_ssl = false
  config.assume_ssl = false

  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.active_support.report_deprecations = false
end
