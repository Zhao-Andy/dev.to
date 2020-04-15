class VerificationMailer < ApplicationMailer
  default from: -> { "DEV Email Verification <#{SiteConfig.default_site_email}>" }

  def verification_email(delete_user, keep_user)
    @user = user
    @verification = generate_account_verification_token(user.id, user.email)
    json_data = {
      delete_user_id: delete_user.id,
      keep_user_id: keep_user.id,
    }
    EmailAuthorization.create(user: user, type_of: "merge_request")
    mail(to: @user.email, subject: "Verify Your DEV Account Access")
  end
end
