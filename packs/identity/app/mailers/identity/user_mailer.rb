module Identity
  # packs/identity/app/mailers/user_mailer.rb
  class UserMailer < ApplicationMailer
    def welcome_email(email)
      @email = email
      mail(to: email, subject: 'Welcome!')
    end

    def magic_link(attempt)
      @attempt = attempt
      @user = attempt.user

      # This is where the email is actually addressed
      mail(
        to: @user.email,
        subject: "Your Magic Login Link"
      )
    end

    def magic_link_email(email, token)
      @email = email
      @magic_link_url = magic_login_url(token: token, host: 'localhost:3000')

      mail(to: @email, subject: 'Your Magic Login Link')
    end
  end
end
