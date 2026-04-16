module Identity
  class RegisterPasskey < Core::BaseService
    def initialize(user_id:, params:, challenge:)
      @user_id = user_id
      @params = params
      @challenge = challenge
    end

    def call
      client_data = JSON.parse(Base64.urlsafe_decode64(@params[:response][:clientDataJSON]))
      browser_challenge = client_data["challenge"]

      puts "DEBUG: Challenge from Rails Cache/Session: #{@challenge}"
      puts "DEBUG: Challenge returned by Browser: #{browser_challenge}"

      if @challenge == browser_challenge
        puts "SUCCESS: Challenges match!"
      else
        puts "ERROR: Challenge mismatch!"
      end
      

      webauthn_credential = WebAuthn::Credential.from_create(@params)
      # 1. Verify the challenge matches what we sent to the frontend
      webauthn_credential.verify(@challenge)

      user = ::Identity::User.find(@user_id)
      
      # Extract the values into simple variables first
      ext_id = webauthn_credential.id.to_s
      pub_key = WebAuthn.standard_encoder.encode(webauthn_credential.public_key).to_s
      sig_count = webauthn_credential.sign_count.to_i
      
       # 2. Save into your existing credentials table
      credential = user.credentials.create!(
        cred_type: 'passkey',
        data: {
          external_id: ext_id,
          public_key: pub_key,
          sign_count: sig_count,
          nickname: @params[:nickname].to_s.presence || "Passkey #{Time.current.to_i}"
        }
      )
      # success(credential)
      success
    rescue WebAuthn::Error => e
      failure("Verification failed: #{e.message}")
    end
  end
end
