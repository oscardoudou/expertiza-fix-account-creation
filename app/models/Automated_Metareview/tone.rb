require 'wordnet'

class Tone
  def identifyTone(posTagger, coreNLPTagger, reviewText)
    cumulativeEdgeFeature = Array.new
    cumulativeReviewTone = Array.new 
    cumulativeReviewTone = [-1, -1] #sum of all edge tones
    
    #extracting positive and negative words from files into arrays
    positiveFile = "/Users/lakshmi/Documents/Thesis/opinion-lexicon-English/positive-words.csv"
    negativeFile = "/Users/lakshmi/Documents/Thesis/opinion-lexicon-English/negative-words.csv"
    positive = Array.new
    negative = Array.new
    FasterCSV.foreach(positiveFile) do |text|
      puts "class of read text #{text.class}"
      positive << text[0]
    end
    #puts "positive list:: #{positive}"
    FasterCSV.foreach(negativeFile) do |text|
      negative << text[0]
    end
    #puts "negative list:: #{negative}"
    
    g = Graphgenerator.new
    g.generateGraph(reviewText, posTagger, coreNLPTagger, false, false)
    reviewEdges = g.edges
    inFeature = Array.new
    outFeature = Array.new
    reviewEdges.each{
      |edge|
      puts "#### Checking for edge #{edge.inVertex.name} - #{edge.outVertex.name}"
      if(!edge.inVertex.nil?)
        inFeature = getFeatureVector(edge.inVertex, positive, negative)
      end  
      if(!edge.outVertex.nil?)
        outFeature = getFeatureVector(edge.outVertex, positive, negative)
      end  
      puts "inFeature :: [#{inFeature[0]}, #{inFeature[1]}]"
      puts "outFeature :: [#{outFeature[0]}, #{outFeature[1]}]"
      cumulativeEdgeFeature[0] = (inFeature[0].to_f + outFeature[0].to_f)/2.to_f
      cumulativeEdgeFeature[1] = (inFeature[1].to_f + outFeature[1].to_f)/2.to_f
      puts "cumulativeEdgeFeature :: [#{cumulativeEdgeFeature[0]}, #{cumulativeEdgeFeature[1]}]"
      if(cumulativeReviewTone[0] == -1 and cumulativeReviewTone[1] == -1) #has not been initialized as yet
        cumulativeReviewTone[0] = cumulativeEdgeFeature[0].to_f
        cumulativeReviewTone[1] = cumulativeEdgeFeature[1].to_f
      else
        cumulativeReviewTone[0] = (cumulativeReviewTone[0].to_f + cumulativeEdgeFeature[0].to_f)/2.to_f
        cumulativeReviewTone[1] = (cumulativeReviewTone[1].to_f + cumulativeEdgeFeature[1].to_f)/2.to_f
      end
      puts "cumulativeReviewTone :: [#{cumulativeReviewTone[0]}, #{cumulativeReviewTone[1]}]"
    }
    puts "cumulative tone :: positive - #{cumulativeReviewTone[0]}, negative - #{cumulativeReviewTone[1]}"
    
    return cumulativeReviewTone
  end 
#--------  
  def getFeatureVector(vertex, positive, negative)    
    threshold = 10 #max distance at which synonyms can be searched
    featureVector = Array.new #size of the array depends on th number of tone dimensions e.g.[positive, negative, netural]
    featureVector = [0, 0] #initializing          
    #look for the presence of token in positive set
    puts "** checking positive"
    if(inSet(positive, vertex.name.downcase))
      featureVector[0] = 1 #
    else 
      #recursively check for synonyms of token in the positive set
      distance = 1
      flag = 0      
      synonymSets = getSynonyms(vertex, threshold) #gets upto 'threshold' levels of synonms in a double dimensional array
      synonymSets.each{
        |set|  
        synonyms = set
        synonyms.each{
          |syn|
          if(inSet(positive, syn))
            featureVector[0] = 1/distance
            flag = 1
            break
          end  
        }
        if(flag == 1)
          break #break out of the loop
        end
        distance+=1 #incrementing to check synonyms in the next level
      }
    end  
      
    # repeat above with negative set
    puts "** checking negative"
    if(inSet(negative, vertex.name.downcase))
      featureVector[1] = 1 #
    else 
      #recursively check for synonyms of token in the positive set
      distance = 1
      flag = 0      
      synonymSets = getSynonyms(vertex, threshold) #gets upto 'threshold' levels of synonms in a double dimensional array
      if(!synonymSets[1].empty?)#i.e. if there were no synonyms identified for the token avoid rechecking for [0] - since that contains the original token
        synonymSets.each{
          |set|  
          synonyms = set
          synonyms.each{
            |syn|
            if(inSet(negative, syn))
              featureVector[1] = 1/distance
              flag = 1
              break
            end  
          }
          if(flag == 1)
            break #break out of the loop
          end
          distance+=1 #incrementing to check synonyms in the next level
        }
      end
    end
    return featureVector
  end
#--------  
=begin
 Compares token with every word in the positive or negative opinion lexicon set 
=end
  def inSet(set, token)
    wbsim = WordnetBasedSimilarity.new
    speller = Aspell.new("en_US")
    speller.suggestion_mode = Aspell::NORMAL
    tokenStem = wbsim.findStemWord(token, speller)
    puts "***looking for #{token}..stem #{tokenStem} .. class #{token.class}"
    set.each{
      |ele|
      eleStem = wbsim.findStemWord(ele, speller)
      #puts "comparing with #{ele.downcase}"
      if(ele.downcase == token or ele.downcase == tokenStem or eleStem == token or eleStem == tokenStem)
        puts "## match found for #{token}.. ele - #{ele}..stem #{eleStem}"
        return true #indicates presence
      end
    }
    return false #indicates absence
  end
#--------
=begin
 getSynonyms - gets synonyms for vertex - upto 'threshold' levels of synonyms
 level 1 = token
 level 2 = token's synonyms
 ...
 level 'threshold' = synonyms of tokens in threshold - 1 level 
=end

  def getSynonyms(vertex, threshold)
    puts "Inside getSynonyms"
    wbsim = WordnetBasedSimilarity.new
    pos = wbsim.determinePOS(vertex)
    speller = Aspell.new("en_US")
    speller.suggestion_mode = Aspell::NORMAL
    
    revSyn = Array.new(threshold+1){Array.new} #contains synonyms for the different levels
    revSyn[0] << vertex.name.downcase #holds the array of tokens whose synonyms are to be identified
    #at first level '0' is the token itself
    i = 0
    while i < threshold do
      listNew = Array.new 
      revSyn[i].each{
        |token|        
        lemmas = WordNet::WordNetDB.find(token) #reviewLemma = revIndex.find(revToken) #
        if(lemmas.nil?)
          lemmas = WordNet::WordNetDB.find(wbsim.findStemWord(token, speller)) #revIndex.find(revStem[0])
        end
        #select the lemma corresponding to the token's POS
        lemma = lemmas[0] #set the first one as the default lemma, later if one with exact POS is found, set that as the lemma 
        lemmas.each do |l|
          #puts "lemma's POS :: #{l.pos} and reviewPOS :: #{pos}"
          if(l.pos.casecmp(pos) == 0)
            lemma = l
          end  
        end
        #puts "selected lemma - #{lemma}"
        #error handling for lemmas's without synsets that throw errors! (likely due to the dictionary file we are using)
        begin #error handling
        #if selected reviewLemma is not nil or empty
        if(!lemma.nil? and lemma != "" and !lemma.synsets.nil?)      
          #creating arrays of all the values for synonyms, hyponyms etc. for the review token
          for g in 0..lemma.synsets.length - 1
            #fetching the first review synset
            reviewLemmaSynset = lemma.synsets[g]
            #synonyms
            revLemmaSyns = reviewLemmaSynset.get_relation("&")
            #for each synset get the values and add them to the array
            for h in 0..revLemmaSyns.length - 1
              listNew[0] = revLemmaSyns[h].words
              #puts"revLemmaSyns[h].words #{revLemmaSyns[h].words} #{revLemmaSyns[h].words.class}"
            end
          end 
        end #end of checking if the lemma is nil or empty
        rescue
          puts "lemma doesn't have any synsets"
        end
      } #end of iterating through revSyn[level]'s tokens
      
      if(listNew.empty?)
        puts "listNew is empty"
        break
      end
      puts "synonyms in level #{i} are #{listNew[0]}"
      i+=1 #level is incremented
      revSyn[i] = listNew[0] #setting synonyms
    end
    return revSyn
  end
  
end