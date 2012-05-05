class AutomatedMetareviewsController < ApplicationController

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
    @automated_metareview.perform_metareviews(@response, params[:id])
    # respond_to do |format|
      # format.html # new.html.erb
      # format.xml  { render :xml => @automated_metareview }
    # end
  end

  # GET /automated_metareviews/1/edit
  # def edit
    # @automated_metareview = AutomatedMetareview.find(params[:id])    
  # end

  def create #getting the 'new' metareview and saving it and redirect to the student_review
    @automated_metareview = AutomatedMetareview.new(params[:automated_metareview])
    respond_to do |format|
      if @automated_metareview.save
        redirect_to :controller => 'responses', :action => 'edit', :id => @map.id
        #format.html { redirect_to(@automated_metareview, :notice => 'AutomatedMetareview was successfully created.') }
        #format.xml  { render :xml => @automated_metareview, :status => :created, :location => @automated_metareview }
      else #go back to the edit responses page, so the reviewer can continue editing
        @map.save #save the reviewer's final response
        redirect_to :controller => 'student_review', :action => 'list', :id => @map.reviewer.id
        #format.html { render :action => "new" }
        #format.xml  { render :xml => @automated_metareview.errors, :status => :unprocessable_entity }
      end
    end
  end

  def save
    puts "saving the automated metareview with response_id #{@automated_metareview.response_id}"
    @automated_metareview.save
  end
end
