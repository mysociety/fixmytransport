class MobileController < ApplicationController
  
  def index
    
    # phone_tree entries: 
    #     first entry:      question (or directives if there are no buttons)
    #     other entries:    key | button-text
    # 
    #     button-text is optional, will duplicate the key
    #     key is truncated to the first word, lowercased
    #     cumulative keys (a path down the tree) separated by |, e.g. "foo|bar"
    phone_tree = {
      :index => [
                    "Please tell us what your problem relates to:",
                    'train',
                    'bus',
                    'tube', 
                    'tram', 
                    'ferry'
                  ],
      'train' => [
                    "And this problem is related to...?",
                    "a train you're currently on",
                    "some other train",
                    "a station",
                    "a route"
                  ],
                  
      'train|station' => [
                    "OK, what's the problem with the station?",
                    "the information is wrong or unhelpful",
                    "broken | something is broken",
                    "the toilets or waiting room are locked",
                    "the ticket machine isn't working",
                    "something else"
                  ],
                  
      'train|station|broken' => [
                    "What's busted?",
                    "escalators",
                    "lifts",
                    "information displays",
                    "ticket machine",
                    "something else"
                  ],

      'train|station|broken|escalators' => ["The escalators at this station are not working."],
      'train|station|broken|lifts' => ["The lifts at this station are not working."],
      'train|station|broken|information' => ["The information displays at this station are not working."],
      'train|station|broken|ticket' => ["The ticket machines at this station are not working."],

      'train|station|information' => [
                    "What's wrong with the information here?",
                    "displays aren't readable",
                    "wrong|displays showing the wrong trains",
                    "no announcements for delays",
                    "no timetables displayed",
                    "can't understand the announcements",
                    "something else"
                  ],


      'bus' =>  [
                    "And this problem is related to a...?",
                    "on   | bus you're currently on",
                    "stop | bus stop",
                    "bus  | bus you're waiting for",
                    "route| bus route"
                ],
      'bus|stop' =>  [
                    "OK &mdash; so what's the problem with this stop?",
                    "miss   | it's missing something important",
                    "broke  | something here has been broken",
                    "other  | something else"
                ],
      'bus|stop|broke' =>  [
                    "Broken bus stop? Tell us what's busted:",
                    "glass",
                    "seat",
                    "digital displays",
                    "paper information",
                    "other  |something else"
                ],      
      'bus|stop|broke|seat' =>  [
                    "Don't sit down, dude."
                  ]
    }
    path = session[:mobile_answers].blank? ? [] : session[:mobile_answers].split("|")
    if params[:answer]
      path.push(params[:answer])
      new_path = path.join("|")
      if phone_tree.has_key?(new_path)
        @buttons = phone_tree[new_path]
        session[:mobile_answers]=new_path
      else
        render :status => '404 Not Found'
      end
    else
      session[:mobile_answers] = "" # reset if we don't have an answer (harsh?)
    end
    @buttons ||= phone_tree[:index]
    @question = @buttons.shift
    if @buttons.length == 0
      # store the problem
      # identify where this is happening
      render :template => "problems/find_stop" and return
      # @buttons = ['OK'] # this is a leaf node: go to mainsteam FMT, populating the input
    end
    render :layout => 'mobile'
  end

  def geolocate
    render :layout => 'mobile_dialog'
  end

  # allow user to manually force device (overrides useragent)
  def select_device
    if params[:device]=='mobile'
      session[:device] = :mobile
    else
      session[:device] = :application        
    end
    flash[:notice] = "device is #{session[:device]}"
    redirect_to root_url and return # no: can't break out of mobile jquery this way TODO
  end
end