class EmailVerificationsController < ApplicationController
  def verify
    # verify throws InvalidSignature error if params[:ut] is invalid
    verified_params = Rails.application.message_verifier(:account_verification).verify(params[:ut])

    if verified_params[:expires_at] > Time.current
      user = User.find_by(id: verified_params[:user_id])
      if user && current_user == user
        email_auth = EmailAuthorization.find_by()
      end
    else
      render "invalid_token"
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    not_found
  end

  def index; end

  def create
    user = User.find_by(email: params[:email])
    if user && email_auth
      VerificationMailer.verification_email(user).deliver_now
    end
    flash[:submit_success] = "Submission successful. If there is a DEV account associated with that email, you will receive a link to verify your access to that account."
    redirect_to "/email_verifications"
  end
end
