require 'Automated_Metareview/textCollection'
require 'Automated_Metareview/graphgenerate'
require 'Automated_Metareview/patternIdentify'
require 'Automated_Metareview/predictClass'

class ReviewContent
# include TextCollection
# include Graphgenerator
attr_accessor :numPatterns  
#if no patterns had been generated earlier  
=begin
 Identify patterns in the training data set 
 posTagger - the pos tagger
 coreNLPTagger - instance of the stanford nlp tagger
 classFileArray - array of files containing the different classes of texts
 patternFileName - array of filenames for patterns from across the different classes
=end
def patternIdentify(posTagger, coreNLPTagger, classFileArray, patternFileName)
  #getting the text    
  #initializing files for the different classes
  numClasses = 0
  classFiles = Array.new
  classFileArray.each do |classF|
    classFiles << classF
    numClasses+=1 
  end
    
  @numPatterns = Array.new
  singlePatterns = Array.new(numClasses){Array.new} #contains single patterns across the different classes
  #Generating the graphs
  tc = TextCollection.new #- modules do not have to be initialized
  for i in (0.. numClasses - 1)
    trainReviews = tc.getReview(0, classFiles[i]) #training set
    puts ("trainReviews class:: #{trainReviews.class} - #{trainReviews.length}")
    puts("!!Generating graphs for training reviews!!")
    g = Graphgenerator.new
    @numPatterns[i] = g.generateGraph(trainReviews[0], posTagger, coreNLPTagger, false, true) #0 is a flag to indicate train reviews
    puts g.edges[0]    
    singlePatterns[i] = g.edges #setting the selected edges for the class
    puts "singlePatterns[i]:: #{singlePatterns[i].length}"
  end 

  #Graphgenerator.edges = nil
  puts("*************************************************")    
  #identification of patterns
  puts("!!Generating patterns for the training reviews!!") 
  pattern = PatternIdentify.new
  pattern.getOrderedPatterns(singlePatterns, @numPatterns, numClasses, patternFileName)
  puts("*************************************************")
end
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
 predict classes for the new reviews  
=end  
def predictClasses(posTagger, coreNLPTagger, reviewText, patternFilesArray, numClasses) 
  #files containing single patterns for the different classes 
  patternsFiles = Array.new
  patternFilesArray.each do |pattF|
    patternsFiles << pattF 
  end
  
  tc = TextCollection.new
  singlePatterns = Array.new(numClasses){Array.new}
  #collecting patterns for every class
  for i in (0..numClasses - 1) #for every class
    singlePatterns[i] = tc.readPatterns(patternsFiles[i], posTagger)
  end
  
  #predicting probabiltities of a review belonging to a class  
  puts("!!Predicting classes for the test reviews!!")    
  clPred = PredictClass.new     
  classProbabilities = clPred.prediction(posTagger, reviewText, singlePatterns, numClasses, coreNLPTagger)
  return classProbabilities
end #end of method

end #end of class