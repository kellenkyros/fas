# config/initializers/webauthn.rb
WebAuthn.configure do |config|
  config.origin = "http://localhost:5173"
  config.rp_name = "FAS App"
end
