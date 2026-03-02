# packs/identity/app/controllers/identity/login_attempts_controller.rb
module Identity
  class LoginAttemptsController < ApplicationController

    include ActionController::Live

    def create
      user = User.find_by(email: params[:email])
      
      if user
        attempt = LoginAttempt.create!(user: user)
        
        # Send the email (handled by Solid Queue in the background)
        # Pass the magic_token to the mailer
        Identity::UserMailer.magic_link(attempt).deliver_later
        
        # Give the Desktop the external_id so it knows which SSE channel to join
        render json: { attempt_id: attempt.external_id }, status: :created
      else
        render json: { error: "User not found" }, status: :not_found
      end
    end
    
    def subscribe
      response.headers['Content-Type'] = 'text/event-stream'
      response.headers['Cache-Control'] = 'no-cache'
      
      sse = ActionController::Live::SSE.new(response.stream)
      channel = "login_#{params[:id]}"
      queue = Queue.new

      # 1. Define the callback as a lambda
      callback = ->(payload) { queue << payload }

      # 2. Pass the channel AND the callback as arguments
      subscriber = ActionCable.server.pubsub.subscribe(channel, callback)

      begin
        loop do
          message = Timeout.timeout(20) { queue.pop }
          sse.write(message, event: "authorized")
          break 
        rescue Timeout::Error
          sse.write({ ping: Time.current }, event: "ping")
        end
      ensure
        # 3. Use the callback to unsubscribe
        ActionCable.server.pubsub.unsubscribe(channel, callback)
        sse.close
      end
    end
  end
end
