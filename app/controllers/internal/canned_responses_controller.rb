class Internal::ResponseTemplatesController < Internal::ApplicationController
  layout "internal"

  def index
    @response_templates = if params[:filter]
                          ResponseTemplate.where(type_of: params[:filter])
                        else
                          ResponseTemplate.all
                        end
    @response_templates = @response_templates.page(params[:page]).per(50)
  end

  def create
    @response_template = ResponseTemplate.new(permitted_params)
    if @response_template.save
      flash[:success] = "Response Template: \"#{@response_template.title}\" saved successfully."
      redirect_to("/internal/response_templates/#{@response_template.id}/edit")
    else
      flash[:danger] = @response_template.errors.full_messages.to_sentence
      @response_templates = ResponseTemplate.all.page(params[:page]).per(50)
      render :index
    end
  end

  def edit
    @response_template = ResponseTemplate.find(params[:id])
  end

  def update
    @response_template = ResponseTemplate.find(params[:id])

    if @response_template.update(permitted_attributes(ResponseTemplate))
      flash[:success] = "The response template \"#{@response_template.title}\" was updated."
    else
      flash[:danger] = @response_template.errors.full_messages.to_sentence
    end

    redirect_back(fallback_location: "/internal/response_templates/#{@response_template.id}")
  end

  def destroy
    @response_template = ResponseTemplate.find(params[:id])

    if @response_template.destroy
      flash[:success] = "The response template \"#{@response_template.title}\" was deleted."
    else
      flash[:danger] = @response_template.errors.full_messages.to_sentence # this will probably never fail
    end

    redirect_to "/internal/response_templates"
  end

  private

  def permitted_params
    params.require(:response_template).permit(:body_markdown, :user_id, :content, :title, :type_of, :content_type)
  end
end
