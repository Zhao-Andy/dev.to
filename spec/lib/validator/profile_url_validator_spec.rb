require "spec_helper"

describe ProfileUrlValidator do
  subject(:user) do
    Class.new do
      include ActiveModel::Validations
      attr_accessor :facebook_url, :stackoverflow_url, :behance_url, :dribbble_url, :medium_url, :gitlab_url, :linkedin_url
      validates :facebook_url, :stackoverflow_url, :behance_url, :dribbble_url, :medium_url, :gitlab_url, :linkedin_url,
        profile_url: true
    end.new
  end

  let(:external_options) { %w(facebook behance dribbble medium gitlab linkedin) }

  def assert_http_or_https_validity(http_or_https)
    external_options.each do |site|
      user.send("#{site}_url=", "#{http_or_https}://#{site}.com/#{Faker::Name.name}")
      expect(user).to be_valid
    end
  end

  context "when url is a valid Facebook, Behance, Dribbble, Medium, or GitLab URL" do
    it "is valid with HTTP links" do
      assert_http_or_https_validity("http")
    end

    it "is valid with HTTPS links" do
      assert_http_or_https_validity("https")
    end
  end

  context "when url is a valid StackOverflow URL" do
    it "is valid with HTTP links" do
      user.stackoverflow_url = "http://stackoverflow.com/users/#{rand(10000..99999)}/#{Faker::Name.name}"
      expect(user).to be_valid
    end

    it "is valid with HTTPS links" do
      user.stackoverflow_url = "https://stackoverflow.com/users/#{rand(10000..99999)}/#{Faker::Name.name}"
      expect(user).to be_valid
    end

    it "allows stackexchange links too" do
      user.stackoverflow_url = "https://dba.stackexchange.com/users/#{rand(10000..99999)}/#{Faker::Name.name}"
      expect(user).to be_valid
    end
  end

  context "when url is blank" do
    it { is_expected.to be_valid }
  end

  context "when url is not a valid StackOverflow URL" do
    before { user.stackoverflow_url = "https://something.com" }

    it { is_expected.not_to be_valid }

    it "produces the correct error message" do
      user.valid?
      expect(user.errors.messages[:stackoverflow_url][0]).to eq "uses an invalid host name"
    end
  end

  context "when url is not a valid Facebook, Behance, Dribbble, Medium, or GitLab URL" do
    it "is not valid" do
      external_options.each do |site|
        user.send("#{site}_url=", "https://something-else.com")
        expect(user).to be_invalid
      end
    end

    it "produces to correct error message" do
      external_options.each do |site|
        user.send("#{site}_url=", "https://something-else.com")
        user.valid?
        expect(user.errors.messages["#{site}_url".to_sym][0]).to eq "uses an invalid host name"
      end
    end
  end
end
