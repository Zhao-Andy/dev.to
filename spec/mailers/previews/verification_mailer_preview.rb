# Preview all emails at http://localhost:3000/rails/mailers/verification_mailer
class VerificationMailerPreview < ActionMailer::Preview
  def verification_email
    VerificationMailer.verification_email(User.find(11))
  end
end
