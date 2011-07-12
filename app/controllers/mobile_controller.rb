class MobileController < ApplicationController
  
  def index
    phone_tree = get_phone_tree
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
    @preamble = @buttons.shift # the preamble is a question (or, if it's a leaf node, the description)
    if @buttons.length == 0
      # the string to populate the problem description is in @preamble
      session[:mobile_problem_text] = @preamble # storing in session? maybe should be saving these as problems in db
      
      # note the template to use here is influenced by answers in the tree path
      # eg, stop or route: depends on how the path (session[:mobile_answers]) starts:
      #   train|route
      #   train|station
      #   train|train
      #   bus|stop
      #   ...etc...
      render :template => "problems/find_stop" and return
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
  
  
  def get_phone_tree
    # phone_tree entries: 
    #     first entry:      question (or directives if there are no buttons)
    #     other entries:    key | button-text
    # 
    #     button-text is optional, will duplicate the key
    #     key is truncated to the first word, lowercased
    #     cumulative keys (a path down the tree) separated by |, e.g. "foo|bar"
    return  {
      :index => [
                    "Please tell us what your problem relates to:",
                    'train',
                    'bus',
                    'tube', 
                    'tram', 
                    'ferry'
                  ],
      
      ### train ---------------------------------------------------
      
      'train' => [
                    "And this problem is related to...?",
                    # "a train you're currently on", 
                    # note: need to 'reuse' branches -- it's now clear this is a graph not a tree
                    #       for example, all the problem reporting is the same for a train you're on or one you're not
                    "a train",
                    "a station",
                    "a route"
                  ],
        'train|train' => [
                      "What's up with the train?",
                      "late|running late",
                      "it's dirty",
                      "toilet| toilet problem",
                      "heat | heating",
                      "info| information",
                      "something else"
                    ],
          'train|train|late' => ["This train is running late"],
          'train|train|dirty' => ["This train is very dirty"],
          'train|train|toilet' => [
                            "Toilet trouble! What's wrong?",
                            "none | no toilets at all",
                            "ooo | all out of order",
                            "dirty | not clean enough",
                            "broken | it's broken",
                            "flood | it's flooded",
                            "lock | lock is broken",
                            "something else"
                          ],
            'train|train|toilet|none' => ["There are no toilets on this train"],
            'train|train|toilet|ooo' => ["All toilets on this train are out of order"],
            'train|train|toilet|dirty' => ["The toilet is not clean enough"],
            'train|train|toilet|broken' => ["The toilet is broken"],
            'train|train|toilet|flood' => ["The toilet is flooded"],
            'train|train|toilet|lock' => ["The lock on the toilet door is broken"],
            'train|train|toilet|else' => ["Something is wrong with the toilets on this train"],
          'train|train|heat' => [
                            "What's wrong with the heating on this train?",
                            "too hot",
                            "too cold",
                            "noise | making funny noise",
                            "something else"
                          ],
            'train|train|heat|hot' => ["There's train is too hot"],
            'train|train|heat|hot' => ["This train is too cold"],
            'train|train|heat|noise' => ["This heating is making a funny noise"],
            'train|train|heat|else' => ["There's something wrong with the heating on this train"],
      'train|station' => [
                    "OK, what's the problem with the station?",
                    "info | information is missing/wrong",
                    "broken | something is broken",
                    "no toilets",
                    "waiting room locked",
                    "ticket machines not working",
                    "something else"
                  ],
        'train|station|info' => [
                    "What's wrong with the information systems here?",
                    "digital | digital displays",
                    "audio | can't hear announcements",
                    "wrong | it's simply wrong",
                    "something else"
                  ],
          'train|station"info|digital' => [
                                      "What's wrong with the digital displays?",
                                      "dead | not working at all",
                                      "it's garbled",
                                      "stuck | not updating",
                                      "something else"
                                  ],
            'train|station|info|digital|dead' => ["The digital displays here are not working at all"],
            'train|station|info|digital|garbled' => ["The digital displays here are garbled"],
            'train|station|info|digital|stuck' => ["The digital displays here are not updating"],
            'train|station|info|digital|else' => ["There's something wrong with the digital displays here"],
        'train|station|broken' => [
                    "What's busted?",
                    "escalators",
                    "lifts",
                    "info | information displays",
                    "ticket machine",
                    "something else"
                  ],
          'train|station|broken|escalators' => ["The escalators at this station are not working."],
          'train|station|broken|lifts' => ["The lifts at this station are not working."],
          'train|station|broken|information' => ["The information displays at this station are not working."],
          'train|station|broken|ticket' => ["The ticket machines at this station are not working."],
          'train|station|info' => [
                        "What's wrong with the information here?",
                        "displays aren't readable",
                        "wrong | displays showing the wrong trains",
                        "delay | no announcements for delays",
                        "no timetables displayed",
                        "something else"
                      ],
            'train|station|info|displays' => ["The information displays are unreadable"],
            'train|station|info|wrong' => ["The information displays are showing the wrong trains"],
            'train|station|info|delay' => ["There are no announcements for delays here"],
            'train|station|info|timetables' => ["There aren't any timetables on display here"],
            'train|station|info|displays' => ["The information displays are unreadable"],
            'train|station|info|else' => ["There's something wrong with the information displays are unreadable"],
      'train|route' => [
            "What's the problem with the route?",
            "late | always late",
            "something else"
          ],
          'train|route|late' => ["The trains on this route are always late"],
          'train|route|else' => ["There's something wrong with this route."],
          
      ### bus ---------------------------------------------------

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
                    "something else"
                ],
      'bus|stop|miss' =>  [
                    "An incomplete bus stop. What's missing?",
                    "sign | the bus stop sign",
                    "shelter | the shelter",
                    "times | timetable information",
                    "something else"
                ],      
        'bus|stop|miss|sign' => ["The bus stop sign is missing from this bustop"],
        'bus|stop|miss|shelter' => ["The bus stop shelter is missing"],
        'bus|stop|miss|times' => ["Timetable information is missing from this bustop"],
        'bus|stop|miss|else' => ["There's something missing from this bustop"],
        'bus|stop|else' =>  ["There's something missing at this stop:"],      
      'bus|stop|broke' =>  [
                    "Broken bus stop? Tell us what's busted:",
                    "glass",
                    "seat",
                    "digital displays",
                    "paper| unreadable printed information",
                    "something else"
                ],      
        'bus|stop|broke|glass' =>  ["The bus stop glass is smashed."],
        'bus|stop|broke|seat' =>  ["The seat at this stop is broken"],
        'bus|stop|broke|digital' =>  ["The digital displayes at this stop are broken"],
        'bus|stop|broke|paper' =>  ["The paper information is unreadable"],
        'bus|stop|broke|else' =>  ["Something at this stop is broken:"],
      
      ### tube ---------------------------------------------------

      ### tram ---------------------------------------------------

      ### ferry ---------------------------------------------------
      
      '_stub' => [] # so trailing comma isn't syntax error
    }
  end
end