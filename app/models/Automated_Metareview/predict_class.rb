require 'Automated_Metareview/wordnetBasedSimilarity'
require 'Automated_Metareview/constants'

class PredictClass
  
@@number_matches = 0
MAX = 15 #MAX number of segments in the review = 15
=begin
 Identifies the probabilities of a review belonging to each of the three classes. 
 Returns an array of probablities (length = numClasses) 
=end
#predicting the test's class
def prediction(posTagger, testReviews, singlePatterns, numClasses, parser)
  wordnet = WordnetBasedSimilarity.new
  maxProbability = 0.0
  classValue = 0
     
  #for every testReview, generate a graph
  #for i in (0..testReviews.length - 1)
    #if(!testReviews[i].nil?)
      #generating graph representation for the test review
      g = Graphgenerator.new
      g.generateGraph(testReviews, posTagger, parser, false, true)
      
      maxProbability = 0.0
      classValue = 0          
      #morphing noun vertices in the patterns
      abstractEdges = g.edges#DegreeOfRelevance.Edges #
      puts "abstractEdges.length #{abstractEdges.length}"
      
      classProb = Array.new #contains the probabilities for each of the classes - it contains 3 rows for the 3 classes    
      #comparing each test review text with patterns from each of the classes
      for k in (0..numClasses - 1)
        classProb[k] = determineClass(abstractEdges, singlePatterns[k], wordnet)
        #only for printing max probability
        if(classProb[k] > maxProbability)
          maxProbability = classProb[k] #setting the probability and class values
          classValue = k
        end       
      end #end of for loop for the classes          
      puts("########## Probability for test review:: "+testReviews[0]+" is:: #{maxProbability} for class:: #{classValue}")      
    #end ##if condition for testReviews is nil
  #end #end of for loop for each test review 
  return classProb
end #end of the prediction method
#------------------------------------------#------------------------------------------#------------------------------------------

def determineClass(singleEdges, singlePatterns, wordnet)
  finalClassSum = 0.0
  finalEdgeNum = 0
  singleEdgeMatches = Array.new(singleEdges.length){Array.new}
  #taking maxmatch with a pattern instead of an average match
  for i in (0..singleEdges.length - 1) #(int i = 0; i < singleEdges.length; i++){
    if(!singleEdges[i].nil?)
      for j in (0..singlePatterns.length - 1) #(int j = 0; j < singlePatterns.length; j++){
        if(!singlePatterns[j].nil?)
          singleEdgeMatches[i][j] = compareEdges(singleEdges[i], singlePatterns[j], wordnet)
        end
      end #end of for loop for the patterns
        
      #calculating average match
      #System.out.println("singleEdges[i].averageMatch before:: "+singleEdges[i].averageMatch);
      puts("Edge-Pattern Match:::")
      count = 0
      for j in (0..singlePatterns.length - 1) #(int j = 0; j < singlePatterns.length; j++){
        if(!singlePatterns[j].nil?) #check ensures you dont add garbage values when no edge existed at "j"
          puts(" - #{singleEdgeMatches[i][j]}")
          singleEdges[i].averageMatch = singleEdges[i].averageMatch + singleEdgeMatches[i][j]
          count+=1
        end
      end
        
      puts("singleEdges[i].averageMatch after:: #{singleEdges[i].averageMatch}")
      puts("count after:: #{count}")
        
      if(count == 0) 
        count = 1 #if matches with all patterns were 0 then count would remain 0 and result in a divide by zero error.
      end
      
      singleEdges[i].averageMatch = singleEdges[i].averageMatch/count
      puts("******** MatchVal for single edge:: #{singleEdges[i].inVertex.name} - #{singleEdges[i].outVertex.name}:: #{singleEdges[i].averageMatch}")
        
      #calculating class average
      if(singleEdges[i].averageMatch != 0.0)
        finalClassSum = finalClassSum + singleEdges[i].averageMatch
        puts("finalClassSum:: #{finalClassSum}")
        finalEdgeNum+=1
      end

      puts("******************************************************************************************************")
    end #end of the if condition
  end #end of for loop
=begin    
//    for(i = 0; i < singleEdges.length; i++){
//      if(singleEdges[i] != null){
//        System.out.println("singleEdges[i].averageMatch::" +singleEdges[i].averageMatch);
=end

  puts("finalClassSum:: #{finalClassSum} finalEdgeNum:: #{finalEdgeNum} Class average #{finalClassSum/finalEdgeNum}")
  return finalClassSum/finalEdgeNum #maxMatch
end #end of determineClass method
#------------------------------------------#------------------------------------------#------------------------------------------

def compareEdges(e1, e2, wordnet)
  #matching in-in and out-out vertices    
  if(e1.nil?) 
    puts("e1 is null")
  end
  if(e2.nil?)
    puts("e2 is null")
  end
    
  avgMatch_withoutsyntax = wordnet.compareStrings(e1.inVertex, e2.inVertex)
  avgMatch_withoutsyntax = (avgMatch_withoutsyntax + wordnet.compareStrings(e1.outVertex, e2.outVertex))/2
  puts("e1 label:: #{e1.label}")
  puts("e2 label:: #{e2.label}")
  #only for without-syntax comparisons
  avgMatch_withoutsyntax = avgMatch_withoutsyntax/compareLabels(e1, e2)
  puts("avgMatch_withoutsyntax:: #{avgMatch_withoutsyntax}")
    
  #matching in-out and out-in vertices   
  avgMatch_withsyntax = wordnet.compareStrings(e1.inVertex, e2.outVertex)
  avgMatch_withsyntax = (avgMatch_withsyntax + wordnet.compareStrings(e1.outVertex, e2.inVertex))/2
  puts("avgMatch_withsyntax:: #{avgMatch_withsyntax}")
    
  if(avgMatch_withoutsyntax > avgMatch_withsyntax)
    #System.out.println("Returning:: "+avgMatch_withoutsyntax);
    return avgMatch_withoutsyntax
  else
    #System.out.println("Returning:: "+avgMatch_withsyntax);
    return avgMatch_withsyntax
  end
end #end of the compareEdges method
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
   SR Labels and vertex matches are given equal importance
   * Problem is even if the vertices didn't match, the SRL labels would cause them to have a high similarity.
   * Consider "boy - said" and "chocolate - melted" - these edges have NOMATCH for vertices, but both edges have the same label "SBJ" and would get an EXACT match, 
   * resulting in an avg of 3! This cant be right!
   * We therefore use the labels to only decrease the match value found from vertices, i.e., if the labels were different.
   * Match value will be left as is, if the labels were the same.
=end
def compareLabels(edge1, edge2)
  result = EQUAL
  if(!edge1.label.nil? and !edge2.label.nil?)
    if(edge1.label.casecmp(edge2.label) == 0)
      result = EQUAL #divide by 1
    else
      result = DISTINCT #divide by 2
    end
  elsif((!edge1.label.nil? and edge2.label.nil?) or (edge1.label.nil? and !edge2.label.nil?))#if only one of the labels was null
    result = DISTINCT
  elsif(edge1.label.nil? and edge2.label.nil?) #if both labels were null!
    result = EQUAL
  end
    
  return result
end #end of the compareLabels method
      
end