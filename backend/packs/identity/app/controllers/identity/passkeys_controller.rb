module Identity
  class PasskeysController < BaseController
    # Require a valid token for every action in this controller
    before_action :authenticate_request, only: [:options, :create]

    # Step 1: Generate options for the browser's FaceID/TouchID prompt
    def options

      result = ::Identity::FetchUserProfile.call(@current_user_id)
      user_email = result.payload[:data][:email]
      # WebAuthn needs a unique ID for the user that isn't their email
      
      current_user = ::Identity::User.find(@current_user_id)
      
      # Generate and store the WebAuthn User ID the first time the user registers a credential
      if current_user.webauthn_id.blank?
        # WebAuthn.generate_user_id produces a binary string.
        # We want to store it in a way that remains 64 bytes or less.
        binary_id = WebAuthn.generate_user_id
        current_user.update!(webauthn_id: binary_id)
      end

      user_options = {
        id: current_user.webauthn_id,
        name: user_email,
        display_name: user_email
      }
      
      # Generate the creation options
      options = WebAuthn::Credential.options_for_create(
        user: user_options,
        exclude: current_user.credentials.passkeys.pluck(Arel.sql("data->>'external_id'")),
        authenticator_selection: {
          resident_key: "required",
          user_verification: "required"
        }
      )

      # IMPORTANT: Store the challenge in a cache! 
      # You MUST verify this challenge in the next step
      Rails.cache.write("passkey_reg_#{@current_user_id}", options.challenge, expires_in: 5.minutes)

      render json: options
    end

    # Step 2: Receive the result from the frontend and save it
    def create
      # Read from Cache
      challenge = Rails.cache.read("passkey_reg_#{@current_user_id}")
      result = Identity::RegisterPasskey.call(
        user_id: @current_user_id,
        params: params,
        challenge: challenge
      )

      if result.success?
        render json: { message: "Passkey registered successfully" }, status: :created
      else
        render json: { errors: [result.message] }, status: :unprocessable_entity
      end
    end

    # LOGIN STEP 1: The "Discoverable" Challenge
    def login_options
      options = WebAuthn::Credential.options_for_get(allow: []) # Empty 'allow' = discoverable
      
      # We need a way to track this specific request
      challenge_id = SecureRandom.hex(12)
      Rails.cache.write("login_challenge_#{challenge_id}", options.challenge, expires_in: 5.minutes)

      render json: { publicKey: options.as_json, challenge_id: challenge_id }
    end

    # LOGIN STEP 2: Verifying the signature
    def login_verify
      webauthn_credential = WebAuthn::Credential.from_get(params[:assertion])
      challenge = Rails.cache.read("login_challenge_#{params[:challenge_id]}")
      
      # The browser returns the webauthn_id in the 'user_handle'
      user = ::Identity::User.find_by!(webauthn_id: webauthn_credential.user_handle.to_s)
      
      # Find the specific key record
      db_credential = user.credentials.passkeys.find_by!("data->>'external_id' = ?", webauthn_credential.id)

      stored_public_key_string = db_credential.data["public_key"]

      binary_public_key = WebAuthn.standard_encoder.decode(stored_public_key_string)

      webauthn_credential.verify(
        challenge,
        public_key: binary_public_key,
        sign_count: db_credential.sign_count
      )

      db_credential.update!(sign_count: webauthn_credential.sign_count)

       # Extract metadata from the request object
      metadata = {
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }

      Identity::GenerateUserSession.call(user: user, metadata: metadata) do |result|
        result.on_success { |data| render json: result.payload, status: :ok }
        result.on_failure { |errors| render json: result.payload, status: :unauthorized }
      end

    end

  end
end

