require 'Automated_Metareview/text_collection'
require 'Automated_Metareview/predict_class'
require 'Automated_Metareview/degree_of_relevance'
require 'Automated_Metareview/plagiarism_check'
require 'Automated_Metareview/tone'
require 'Automated_Metareview/text_quantity'

class AutomatedMetareview < ActiveRecord::Base
  #belongs_to :response, :class_name => 'Response', :foreign_key => 'response_id'
  #has_many :scores, :class_name => 'Score', :foreign_key => 'response_id', :dependent => :destroy
  attr_accessor :responses, :url
  #the code that drives the metareviewing
  def calculate_metareview_metrics(response, map_id)
    
    puts "inside perform_metareviews!!"    
    tc = TextCollection.new
    puts "map_id #{map_id}"
    #fetch the review data as an array 
    review_text = fetch_review_data(map_id, tc)
       
    #fetching submission data as an array    
    subm_text = fetch_submission_data(map_id, tc)
    
    # #initializing the pos tagger and nlp tagger/semantic parser  
    # pos_tagger = EngTagger.new
    # core_NLP_tagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
#     
    # # #---------    
    # # #relevance
    # beginning_time = Time.now
    # relev = DegreeOfRelevance.new
    # self.relevance = relev.get_relevance(review_text, subm_text, 1, pos_tagger, core_NLP_tagger) #1 indicates the number of reviews
    # #assigninging the graph generated for the review to the class variable, in order to reuse it for content classification
    # review_graph = relev.review
    # puts "review's #edges - #{review_graph.edges.length}"
    # #calculating end time
    # end_time = Time.now
    # relevance_time = end_time - beginning_time
#     
    # #---------    
    # # checking for plagiarism
    # beginning_time = Time.now
    # plag_instance = PlagiarismChecker.new
    # result = plag_instance.check_for_plagiarism(review_text, subm_text)
    # if(result == true)
      # self.plagiarism = "TRUE"
    # else
      # self.plagiarism = "FALSE"
    # end
    # end_time = Time.now
    # plagiarism_time = end_time - beginning_time
#     
    # #---------      
    # #content
    # beginning_time = Time.now
    # content_instance = PredictClass.new
    # pattern_files_array = ["app/models/Automated_Metareview/patterns-assess.csv",
      # "app/models/Automated_Metareview/patterns-prob-detect.csv",
      # "app/models/Automated_Metareview/patterns-suggest.csv"]
    # #predcting class - last parameter is the number of classes
    # content_probs = content_instance.predict_classes(pos_tagger, core_NLP_tagger, review_text, review_graph, pattern_files_array, pattern_files_array.length)
    # #self.content = "SUMMATIVE - #{(content_probs[0] * 10000).round.to_f/10000}, PROBLEM - #{(content_probs[1] * 10000).round.to_f/10000}, SUGGESTION - #{(content_probs[2] * 10000).round.to_f/10000}"
    # end_time = Time.now
    # content_time = end_time - beginning_time
    # self.content_summative = content_probs[0]# * 10000).round.to_f/10000
    # self.content_problem = content_probs[1] #* 10000).round.to_f/10000
    # self.content_advisory = content_probs[2] #* 10000).round.to_f/10000
#     
#     
    # #---------    
    # # tone
    # beginning_time = Time.now
    # ton = Tone.new
    # tone_array = Array.new
    # tone_array = ton.identify_tone(pos_tagger, core_NLP_tagger, review_text, review_graph)
    # self.tone_positive = tone_array[0]#* 10000).round.to_f/10000
    # self.tone_negative = tone_array[1]#* 10000).round.to_f/10000
    # self.tone_neutral = tone_array[2]#* 10000).round.to_f/10000
    # #self.tone = "POSITIVE - #{(tone_array[0]* 10000).round.to_f/10000}, NEGATIVE - #{(tone_array[1]* 10000).round.to_f/10000}, NEUTRAL - #{(tone_array[2]* 10000).round.to_f/10000}"
    # end_time = Time.now
    # tone_time = end_time - beginning_time
#    
#    
    # # #---------
    # # quantity
    # beginning_time = Time.now
    # quant = TextQuantity.new
    # self.quantity = quant.number_of_unique_tokens(review_text)
    # end_time = Time.now
    # quantity_time = end_time - beginning_time
# #     
# #     
    # # # #---------     
    # # # fetch version_num for this new response_id if previous versions of this response already exists in the table
    # @metas = AutomatedMetareview.find(:first, :conditions => ["response_id = ?", self.response_id], :order => "version_num DESC")
    # if !@metas.nil? and !@metas.version_num.nil?
      # version = @metas.version_num + 1
    # else
      # version = 1 #no metareviews exist with that response_id, so set the version to 1
    # end
    # self.version_num = version
#     
    # #printing output with time taken by each metric
    # puts "RELEVANCE ::== #{self.relevance} .. Time elapsed ::= #{relevance_time}"
    # puts "PLAGIARISM ::== #{self.plagiarism} ..  Time elapsed ::= #{plagiarism_time}"
    # puts "CONTENT PROBABILITITES ::== SUMMATIVE - #{content_probs[0]}, PROBLEM - #{content_probs[1]}, SUGGESTION - #{content_probs[2]} ..  Time elapsed ::= #{content_time}"
    # puts "TONE:: Time elapsed ::= #{tone_time}"
    # puts "self.quantity #{self.quantity} .. Time elapsed ::= #{quantity_time}" 
    
    # #dummy variables
    self.version_num = 1
    self.content_summative = 0.543232424
    self.content_problem = 0.43231223 
    self.content_advisory =  0.321331223
    self.relevance = 0.543232424
    self.quantity = 5
    # self.tone = "positive"
    self.tone_positive = 0.5346653754
    self.tone_negative = 0.4235346457
    self.tone_neutral =  0.21313131223
    self.plagiarism = false  
  end
  
  def fetch_review_data(map_id, tc)
    review_array = Array.new
    @responses = Response.find(:first, :conditions => ["map_id = ?", map_id], :order => "version_num DESC")
    self.response_id = @responses.id
    puts "self.response_id #{self.response_id}"
    #puts "responses version number #{responses.version_num}"
    @responses.scores.each{
      | review_score |
      if(review_score.comments != nil and !review_score.comments.rstrip.empty?)
        puts review_score.comments
        review_array << review_score.comments        
      end
    }
    review_text = tc.get_review(0, review_array) #flag is 0, since it is a single review (although it has several sentences)
    puts "ReviewArray #{review_array}... length #{review_array.length}.. reviewText.length #{review_text.length}"
    return review_text 
  end
  
  
  def fetch_submission_data(map_id, tc)
    subm_array = Array.new
    reviewee_id = ResponseMap.find(:first, :conditions => ["id = ?", map_id]).reviewee_id
    @url = Participant.find(:first, :conditions => ["id = ?", reviewee_id]).submitted_hyperlinks
    @url = url[url.rindex("http")..url.length-2] #use "rindex" to fetch last occurrence of the substring - useful if there are multiple urls
    puts "***url #{@url} #{@url.class}"
    require 'open-uri'
    page = Nokogiri::HTML(open(@url))
    page.css('p').each do |subm|
      puts "subm.text.. #{subm.text}"
      subm_array << subm.text 
    end   
    #sample subm_array
    # subm_array << "this is good!"
    # subm_array << "This is interesting!"
    
    #1 indicates testing, which is how we want to collect the reviews or submissions
    subm_text = tc.get_review(0, subm_array)
    # puts "SubmArray length #{subm_array.length}.. submText.class #{subm_text.class} ..submText.length #{subm_text.length}"
    return subm_text  
  end
  
  
=begin
The following method 'send_metareview_metrics_email' sends an email to the reviewer 
listing his/her metareview metrics values.  
=end  

   def send_metareview_metrics_email(response, map_id)
     response_id = self.response_id
     reviewer_id = ResponseMap.find_by_id(map_id).reviewer
     
     reviewer_email = User.find_by_id(Participants.fin_by_id(reviewer_id).user_id).email
     reviewed_url = @url
      
     body_text = "The metareview metrics for review #{@url} are as follows: " 
     body_text = body_text + " Relevance: " + self.relevance
     body_text = body_text + " Quantity: " + self.plagiarism
     body_text = body_text + " Plagiarised: " + self.quantity
     body_text = body_text + " Content Type: Summative content " + self.content_summative.to_s + 
                " Problem content "+self.content_problem.to_s + " Advisory content " + self.content_advisory
     body_text = body_text + " Tone Type: Postive tone " + self.tone_positive.to_s + 
                " Negative tone "+self.tone_negative.to_s + " Neutral tone " + self.tone_neutral

    Mailer.deliver_message(
            {:recipients => reviewer_email,
             :subject => "Your metareview metrics for review of Assignment",
             :from => email_form[:from],
             :body => {
                     :body_text => body_text
             }
            }
    )

    flash[:notice] = "Your metareview metrics have been emailed."
  end
end