require 'Automated_Metareview/textCollection'
require 'Automated_Metareview/review_content'
require 'Automated_Metareview/degreeOfRelevance'
require 'Automated_Metareview/plagiarismChecker'
require 'Automated_Metareview/tone'
require 'Automated_Metareview/textQuantity'

class AutomatedMetareview < ActiveRecord::Base
  #belongs_to :response, :class_name => 'Response', :foreign_key => 'response_id'
  #has_many :scores, :class_name => 'Score', :foreign_key => 'response_id', :dependent => :destroy
  attr_accessor :responses
  #the code that drives the metareviewing
  def perform_metareviews(response, map_id)
    puts "inside perform_metareviews!!"    
    tc = TextCollection.new
    
    #fetch the review and submission data
    reviewArray = Array.new
    @responses = Response.find(:first, :conditions => ["map_id = ?", map_id], :order => "version_num DESC")
    self.response_id = @responses.id
    puts "self.response_id #{self.response_id}"
    #puts "responses version number #{responses.version_num}"
    @responses.scores.each{
      | reviewScore |
      if(reviewScore.comments != nil and !reviewScore.comments.rstrip.empty?)
        puts reviewScore.comments
        reviewArray << reviewScore.comments        
      end
    }    
    reviewText = tc.getReview(0, reviewArray) #flag is 0, since it is a single review (although it has several sentences)
    puts "ReviewArray #{reviewArray}... length #{reviewArray.length}.. reviewText.class #{reviewText.class}"
    
    #fetching submission data
    submArray = Array.new
    reviewee_id = ResponseMap.find(:first, :conditions => ["id = ?", map_id]).reviewee_id
    url = Participant.find(:first, :conditions => ["id = ?", reviewee_id]).submitted_hyperlinks
    url = url[url.rindex("http")..url.length-2] #use "rindex" to fetch last occurrence of the substring - useful if there are multiple urls
    puts "***url #{url} #{url.class}"
    require 'open-uri'
    page = Nokogiri::HTML(open(url))
    page.css('p').each do |subm|
      #puts subm.text
      submArray << subm.text 
    end   
    #1 indicates testing, which is how we want to collect the reviews or submissions
    submText = tc.getReview(0, submArray)
    puts "SubmArray length #{submArray.length}.. submText.class #{submText.class}" 
    
    #initializing the pos tagger and nlp tagger/semantic parser  
    posTagger = EngTagger.new
    coreNLPTagger =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
    
    #---------    
    # relevance
    relev = DegreeOfRelevance.new
    self.relevance = relev.getRelevance(reviewText, submText, 1, posTagger, coreNLPTagger) #1 indicates the number of reviews
    puts "RELEVANCE ::== #{self.relevance}"
    
    #---------    
    #checking for plagiarism
    plag = PlagiarismChecker.new
    self.plagiarism = plag.plagiarismCheck(reviewText, submText)
    puts "PLAGIARISM ::== #{self.plagiarism}"
    
    #---------      
    #content
    cont = ReviewContent.new
    patternFilesArray = ["/Users/lakshmi/Documents/Thesis/Ruby-test/content-patterns/patterns-assess.csv",
      "/Users/lakshmi/Documents/Thesis/Ruby-test/content-patterns/patterns-prob-detect.csv",
      "/Users/lakshmi/Documents/Thesis/Ruby-test/content-patterns/patterns-suggest.csv"]
    #predcting class - last parameter is the number of classes
    content_probs = cont.predictClasses(posTagger, coreNLPTagger, reviewText, patternFilesArray, patternFilesArray.length)
    puts "CONTENT PROBABILITITES ::== SUMMATIVE - #{content_probs[0]}, PROBLEM - #{content_probs[1]}, SUGGESTION - #{content_probs[2]}"
    self.content = "SUMMATIVE - #{content_probs[0]}, PROBLEM - #{content_probs[1]}, SUGGESTION - #{content_probs[2]}"
    
    #---------    
    #tone
    ton = Tone.new
    toneArray = Array.new
    toneArray = ton.identifyTone(posTagger, coreNLPTagger, reviewText)
    if(toneArray[0] == 0 and toneArray[1] == 0)
      toneArray[2] = 1 #setting neutrality value
    else
      toneArray[2] = 0
    end
    self.tone = "POSITIVE - #{toneArray[0]}, NEGATIVE - #{toneArray[1]}, NEUTRAL - #{toneArray[2]}"
    
    #---------
    #quantity
    quant = TextQuantity.new
    self.quantity = quant.numberOfUniqueTokens(reviewArray)
    puts "self.quantity #{self.quantity}"
    
  end
  
  def save
    
  end
    
end