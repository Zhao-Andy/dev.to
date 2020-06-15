class ModerationsController < ApplicationController
  after_action :verify_authorized, except: [:mod_center_article]

  JSON_OPTIONS = {
    only: %i[title published_at cached_tag_list path],
    include: {
      user: { only: %i[username name path] }
    }
  }.freeze

  def index
    skip_authorization
    return unless current_user&.trusted

    articles = Article.published.
      where("score > -5 AND score < 5").
      order("published_at DESC").limit(70)
    articles = articles.cached_tagged_with(params[:tag]) if params[:tag].present?
    articles = articles.where("nth_published_by_author > 0 AND nth_published_by_author < 4 AND published_at > ?", 7.days.ago) if params[:state] == "new-authors"
    @articles = articles.includes(:user).to_json(JSON_OPTIONS)
    @tag = Tag.find_by(name: params[:tag]) || not_found if params[:tag].present?
    @current_user_tags = current_user.moderator_for_tags
  end

  def mod_center_article
    @article = Article.find_by(path: "/#{params[:username].downcase}/#{params[:slug]}").decorate
    # TODO: handle 404
    # TODO: add authorization
    @user = @article.user
    @organization = @article.organization

    if @article.collection
      @collection = @article.collection

      # we need to make sure that articles that were cross posted after their
      # original publication date appear in the correct order in the collection,
      # considering non cross posted articles with a more recent publication date
      @collection_articles = @article.collection.articles.
        published.
        order(Arel.sql("COALESCE(crossposted_at, published_at) ASC"))
    end

    @comments_to_show_count = @article.cached_tag_list_array.include?("discuss") ? 50 : 30

    @second_user = User.find(@article.second_user_id) if @article.second_user_id.present?
    @third_user = User.find(@article.third_user_id) if @article.third_user_id.present?

    @user_json_ld = {
      "@context": "http://schema.org",
      "@type": "Person",
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": URL.user(@user)
      },
      "url": URL.user(@user),
      "sameAs": user_same_as,
      "image": ProfileImage.new(@user).get(width: 320),
      "name": @user.name,
      "email": @user.email_public ? @user.email : nil,
      "jobTitle": @user.employment_title.presence,
      "description": @user.summary.presence || "404 bio not found",
      "disambiguatingDescription": user_disambiguating_description,
      "worksFor": [user_works_for].compact,
      "alumniOf": @user.education.presence
    }.reject { |_, v| v.blank? }

    @mod_panel_open_on_load = true
  end

  def article
    load_article
    render template: "moderations/mod"
  end

  def comment
    authorize(User, :moderation_routes?)
    @moderatable = Comment.find(params[:id_code].to_i(26))
    render template: "moderations/mod"
  end

  def actions_panel
    load_article
    tag_mod_tag_ids = @tag_moderator_tags.pluck(:id)
    has_room_for_tags = @moderatable.tag_list.size < 4
    has_no_relevant_adjustments = @adjustments.pluck(:tag_id).intersection(tag_mod_tag_ids).size.zero?
    can_be_adjusted = @moderatable.tags.pluck(:id).intersection(tag_mod_tag_ids).size.positive?

    @should_show_adjust_tags = tag_mod_tag_ids.size.positive? && ((has_room_for_tags && has_no_relevant_adjustments) || (!has_room_for_tags && has_no_relevant_adjustments && can_be_adjusted))

    render template: "moderations/actions_panel"
  end

  private

  def load_article
    authorize(User, :moderation_routes?)
    @tag_adjustment = TagAdjustment.new
    @moderatable = Article.find_by(slug: params[:slug])
    not_found unless @moderatable
    @tag_moderator_tags = Tag.with_role(:tag_moderator, current_user)
    @adjustments = TagAdjustment.where(article_id: @moderatable.id)
    @already_adjusted_tags = @adjustments.map(&:tag_name).join(", ")
    @allowed_to_adjust = @moderatable.class.name == "Article" && (current_user.has_role?(:super_admin) || @tag_moderator_tags.any?)
    @hidden_comments = @moderatable.comments.where(hidden_by_commentable_user: true)
  end

  def user_works_for
    # For further examples of the worksFor and disambiguatingDescription properties,
    # please refer to this link: https://jsonld.com/person/
    return unless @user.employer_name.presence || @user.employer_url.presence

    {
      "@type": "Organization",
      "name": @user.employer_name,
      "url": @user.employer_url
    }.reject { |_, v| v.blank? }
  end

  def user_disambiguating_description
    [@user.mostly_work_with, @user.currently_hacking_on, @user.currently_learning].compact
  end

  def user_same_as
    # For further information on the sameAs property, please refer to this link:
    # https://schema.org/sameAs
    [
      @user.twitter_username.presence ? "https://twitter.com/#{@user.twitter_username}" : nil,
      @user.github_username.presence ? "https://github.com/#{@user.github_username}" : nil,
      @user.mastodon_url,
      @user.facebook_url,
      @user.youtube_url,
      @user.linkedin_url,
      @user.behance_url,
      @user.stackoverflow_url,
      @user.dribbble_url,
      @user.medium_url,
      @user.gitlab_url,
      @user.instagram_url,
      @user.twitch_username,
      @user.website_url,
    ].reject(&:blank?)
  end
end
