class AutomatedMetareviewsController < ApplicationController
  attr_accessor :automated_metareviews
  def index
    @automated_metareviews = AutomatedMetareview.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @automated_metareviews }
    end
  end

  def list
    @automated_metareview = AutomatedMetareview.new
    #pass in the response id as a parameter
    @response = Response.find_by_map_id(params[:id])
    @automated_metareview.calculate_metareview_metrics(@response, params[:id])
    #puts "response_id - #{@automated_metareview.response_id}, content - #{@automated_metareview.content}, quantity - #{@automated_metareview.quantity}"
    if @automated_metareview.save!
      flash[:notice] = 'Automated Metareview Saved!'
      puts "SAVED SUCESSFULLY - #{@automated_metareview.response_id}"
    else
      flash[:error] = 'Automated Metareview Not Saved'
      puts "NOT SAVED!"
    end
    
    #fetching average metrics values
    avg_existing_metareviews = AutomatedMetareview.find_by_sql(["select avg(relevance) as relevance, avg(content_summative) as summative, 
      avg(content_problem) as problem, avg(content_advisory) as advisory, avg(tone_positive) as positive, avg(tone_negative) as negative, 
      avg(tone_neutral) as neutral, avg(quantity) as quantity from automated_metareviews where response_id <> ?", @automated_metareview.response_id])[0]
    
    #if any of the values are -ve, set them as 0 (for graph display)
    if(avg_existing_metareviews.relevance < 0)
      avg_existing_metareviews.relevance = 0
    end
    if(avg_existing_metareviews.summative.to_f < 0)
      avg_existing_metareviews.summative = 0
    end
    if(avg_existing_metareviews.problem.to_f < 0)
      avg_existing_metareviews.problem = 0
    end
    if(avg_existing_metareviews.advisory.to_f < 0)
      avg_existing_metareviews.advisory = 0
    end
    if(avg_existing_metareviews.positive.to_f < 0)
      avg_existing_metareviews.positive = 0
    end
    if(avg_existing_metareviews.negative.to_f < 0)
      avg_existing_metareviews.negative = 0
    end
    if(avg_existing_metareviews.neutral.to_f < 0)
      avg_existing_metareviews.neutral = 0
    end
    #for current metareview values
    if(@automated_metareview.relevance.to_f < 0)
      @automated_metareview.relevance = 0
    end
    if(@automated_metareview.content_summative.to_f < 0)
      @automated_metareview.content_summative = 0
    end
    if(@automated_metareview.content_problem.to_f < 0)
      @automated_metareview.content_problem = 0
    end
    if(@automated_metareview.content_advisory.to_f < 0)
      @automated_metareview.content_advisory = 0
      # puts "After setting to 0 .. @automated_metareview.content_advisory .. #{@automated_metareview.content_advisory}"
    end
    if(@automated_metareview.tone_positive.to_f < 0)
      @automated_metareview.tone_positive = 0
    end
    if(@automated_metareview.tone_negative.to_f < 0)
      @automated_metareview.tone_negative = 0
    end
    if(@automated_metareview.tone_neutral.to_f < 0)
      @automated_metareview.tone_neutral = 0
    end
    
    #creating the arrays to be graphed
    current_metareview_data = [@automated_metareview.relevance.to_f, @automated_metareview.content_summative.to_f , 
      @automated_metareview.content_problem.to_f, @automated_metareview.content_advisory.to_f, @automated_metareview.tone_positive.to_f, 
      @automated_metareview.tone_negative.to_f, @automated_metareview.tone_neutral.to_f]
    existing_metareview_data = [avg_existing_metareviews.relevance.to_f, avg_existing_metareviews.summative.to_f, 
      avg_existing_metareviews.problem.to_f, avg_existing_metareviews.advisory.to_f, avg_existing_metareviews.positive.to_f, 
      avg_existing_metareviews.negative.to_f, avg_existing_metareviews.neutral.to_f]
    
    #printing values
    #puts "avg_existing_metareviews.class #{avg_existing_metareviews.class}"
    # puts "avg_existing_metareviews.relevance #{avg_existing_metareviews.relevance}, avg_existing_metareviews.summative #{avg_existing_metareviews.summative.to_f}"
    # puts "avg_existing_metareviews.problem #{avg_existing_metareviews.problem}, avg_existing_metareviews.advisory #{avg_existing_metareviews.advisory.to_f}"
    # puts "avg_existing_metareviews.positive #{avg_existing_metareviews.positive}, avg_existing_metareviews.negative #{avg_existing_metareviews.negative.to_f}"
    # puts "avg_existing_metareviews.neutral #{avg_existing_metareviews.neutral}, avg_existing_metareviews.quantity #{avg_existing_metareviews.quantity.to_f}"
#     
    # #puts "@automated_metareview.relevance.class #{@automated_metareview.relevance.class}"
    # puts "@automated_metareview.relevance #{@automated_metareview.relevance}, @automated_metareview.relevance.summative #{@automated_metareview.content_summative.to_f}"
    # puts "@automated_metareview.problem #{@automated_metareview.content_problem}, @automated_metareview.advisory #{@automated_metareview.content_advisory.to_f}"
    # puts "@automated_metareview.positive #{@automated_metareview.tone_positive}, @automated_metareview.negative #{@automated_metareview.tone_negative.to_f}"
    # puts "@automated_metareview.neutral #{@automated_metareview.tone_neutral}, @automated_metareview.quantity #{@automated_metareview.quantity.to_f}"
#     
    color_1 = 'c53711'
    color_2 = '0000ff'
    #names_array = ["Relevance","Summative Content","Problem Content", "Advisory Content", "Positive Tone", "Negative Tone", "Neutral Tone"]
    #labels in reverse order of content being displayed
    names_array = ["Neutral Tone", "Negative Tone", "Positive Tone", "Advisory Content", "Problem Content", "Summative Content", "Relevance"]
    GoogleChart::BarChart.new("500x450", "Your work Vs Average performance on reviews", :horizontal, false) do |bc|
      bc.data "Your work", current_metareview_data, color_1
      bc.data "Avg. performance on reviews", existing_metareview_data, color_2
      bc.axis :y, :labels => names_array, :font_size => 10
      bc.axis :x, :range => [0,1]
      bc.show_legend = true
      bc.stacked = false
      bc.data_encoding = :extended
      bc.shape_marker :circle, :color => '00ff00', :data_set_index => 0, :data_point_index => -1, :pixel_size => 10
      #puts bc.to_url
      @graph = bc.to_url
    end
    
    # if @automated_metareview.save
      # puts "SAVED SUCCESSFULLY"
      # redirect_to :controller => 'student_review', :action => 'list', :id => @map.reviewer.id
    # else
      # redirect_to :controller => 'response', :action => 'edit', :id => @map.id
    # end
  end
  
  
  # def save #getting the 'new' metareview and saving it and redirect to the student_review
    # flash[:notice] = 'Automated Metareview not saved'
    # # puts "params[:id] - #{params[:id]}"
    # # @automated_metareview = params[:object]
    # # puts "#{@automated_metareview.response_id}"
    # # puts "saving the automated metareview with response_id - #{@automated_metareview.response_id}"
    # # #@automated_metareview = AutomatedMetareview.new(params[:automated_metareview])
    # # @automated_metareview.save #final metareview response is saved (the review response version is already saved)
    # redirect_to :controller => 'student_review', :action => 'list', :id => @map.reviewer.id
  # end
end
