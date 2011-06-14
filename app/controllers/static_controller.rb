class StaticController < ApplicationController
  
  def feedback
    if request.post?
      @feedback = Feedback.new(params[:feedback]) 
      respond_to do |format|
        format.html do
          if @feedback.valid? 
            ProblemMailer.deliver_feedback(params[:feedback])
            flash[:notice] = t(:feedback_thanks)
            redirect_to(root_url)
          else
            render 'feedback'
          end
        end
        format.json do 
          @json = {}
          if @feedback.valid? 
            ProblemMailer.deliver_feedback(params[:feedback])
            @json[:success] = true
          else
            @json[:success] = false
            add_json_errors(@feedback, @json)
          end
          render :json => @json
        end
      end
    end
  end
  
  # probably won't end up living in the static_controller, but for now it's a home
  def facebook
    # NB max width for canvas should be 760px
    if params[:request_ids].blank?
      flash[:notice] = "No request_ids"
    elsif params[:signed_request].blank?
      flash[:notice] = "No signed request posted"
    else
      # request_ids = params[:request_ids]
      sig, encoded_json = params[:signed_request].split('.')
      json = ActiveSupport::JSON.decode(base64_url_decode(encoded_json))      
      user_id = json['user_id']
      #uri = URI.parse("https://graph.facebook.com/oauth/access_token?client_id=#{@app.app_id}&redirect_uri=#{@app.connect_url}?verifier=#{verifier}&client_secret=#{@app.secret}&code=#{CGI::escape(code)}")
          # http = Net::HTTP.new(uri.host, uri.port)
          #       http.use_ssl = true
          # 
          #       request = Net::HTTP::Get.new(uri.path + "?" + uri.query)
          #       response = http.request(request)     
          #       data = response.body
          # 
          #       return data.split("=")[1]
      # user_id, oauth_token
      flash[:notice] = "user_id is #{user_id}, sig is #{sig}, JSON is #{json}"
      # get the request, determine which campaign this is for:
      # for now, provide a link, but later can break out of facebook iframe(?)
      # delete the request at Facebook
      # note: more complex -- may need to sweep up =all= requests
    end
  end
  
  private
  def base64_url_decode(str)
     str += '=' * (4 - str.length.modulo(4)) # funky padding fix
     Base64.decode64(str.tr('-_','+/'))
   end
  
end