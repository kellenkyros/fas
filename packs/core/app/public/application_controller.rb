# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  # This catches anything that inherits from StandardError (almost all app crashes)
  rescue_from StandardError, with: :handle_500

  private

  def handle_500(exception)
    # 1. Log it so YOU can see what happened in the terminal/logs
    # Includes the message and the first 5 lines of the stack trace
    backtrace = exception.backtrace.first(5).join("\n")
    Rails.logger.error "‼️ 500 ERROR: #{exception.message}\n#{backtrace}"

    # 2. Render the "Better" error for the client
    render json: {
      success: false,
      error: {
        type: "server_error",
        message: "We encountered an unexpected issue. Our team has been notified.",
        tracking_id: request.request_id # Helpful for debugging later
      }
    }, status: :internal_server_error
  end
end
