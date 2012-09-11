require 'Automated_Metareview/graph_generator'
require 'Automated_Metareview/wordnet_based_similarity'
require 'Automated_Metareview/constants'

class Tone
  def identify_tone(pos_tagger, core_NLP_tagger, review_text)
    
    speller = Aspell.new("en_US")
    speller.suggestion_mode = Aspell::NORMAL
    
    cumulative_edge_feature = Array.new
    cumulative_review_tone = Array.new 
    cumulative_review_tone = [-1, -1, -1] #sum of all edge tones
    
    #extracting positive and negative words from files into arrays
    positive_file = "app/models/Automated_Metareview/positive-words.csv"
    negative_file = "app/models/Automated_Metareview/negative-words.csv"
    positive = Array.new
    negative = Array.new
    FasterCSV.foreach(positive_file) do |text|
      #puts "class of read text #{text.class}"
      positive << text[0]
    end
    #puts "positive list:: #{positive}"
    FasterCSV.foreach(negative_file) do |text|
      negative << text[0]
    end
    #adding other negative words or descriptors to this list
    # NEGATIVE_DESCRIPTORS.each{
      # |neg_des|
      # negative << neg_des
    # }
    negative = negative + NEGATIVE_DESCRIPTORS
    #puts "negative list:: #{negative}"
    
    g = GraphGenerator.new
    g.generate_graph(review_text, pos_tagger, core_NLP_tagger, false, false)
    wbsim = WordnetBasedSimilarity.new
    review_edges = g.edges
    in_feature = Array.new
    out_feature = Array.new
    review_edges.each{
      |edge|
      puts "#### Checking for edge #{edge.in_vertex.name} - #{edge.out_vertex.name}"
      if(!edge.in_vertex.nil?)
        in_feature = get_feature_vector(edge.in_vertex, positive, negative, speller)
      end  
      if(!edge.out_vertex.nil?)
        out_feature = get_feature_vector(edge.out_vertex, positive, negative, speller)
      end  
      
      puts "in_feature :: [#{in_feature[0]}, #{in_feature[1]}]"
      puts "out_feature :: [#{out_feature[0]}, #{out_feature[1]}]"
      
      #making sure that we don't include frequent tokens' tones while calculating cumulative edge tone (both + and -)
      if(!wbsim.is_frequent_word(edge.in_vertex.name) and !wbsim.is_frequent_word(edge.out_vertex.name))
        cumulative_edge_feature[0] = (in_feature[0].to_f + out_feature[0].to_f)/2.to_f
        cumulative_edge_feature[1] = (in_feature[1].to_f + out_feature[1].to_f)/2.to_f
      elsif(wbsim.is_frequent_word(edge.in_vertex.name) and !wbsim.is_frequent_word(edge.out_vertex.name))
        cumulative_edge_feature[0] = out_feature[0].to_f
        cumulative_edge_feature[1] = out_feature[1].to_f
      elsif(!wbsim.is_frequent_word(edge.in_vertex.name) and wbsim.is_frequent_word(edge.out_vertex.name))
        cumulative_edge_feature[0] = in_feature[0].to_f
        cumulative_edge_feature[1] = in_feature[1].to_f
      else
        cumulative_edge_feature[0] = 0
        cumulative_edge_feature[1] = 0
      end
      
      puts "cumulative_edge_feature :: [#{cumulative_edge_feature[0]}, #{cumulative_edge_feature[1]}]"
      if((cumulative_review_tone[0] == -1 and cumulative_review_tone[1] == -1) or 
        (cumulative_review_tone[0] == 0 and cumulative_review_tone[1] == 0)) #has not been initialized as yet
        cumulative_review_tone[0] = cumulative_edge_feature[0].to_f
        cumulative_review_tone[1] = cumulative_edge_feature[1].to_f
      elsif(cumulative_edge_feature[0] > 0 or cumulative_edge_feature[1] > 0)
        #only edges with some tone (either vertices) are taken into consideration during cumulative edge calculation
        #else all edges will be considered, which may adversely affect the net tone of the review text
        cumulative_review_tone[0] = (cumulative_review_tone[0].to_f + cumulative_edge_feature[0].to_f)/2.to_f
        cumulative_review_tone[1] = (cumulative_review_tone[1].to_f + cumulative_edge_feature[1].to_f)/2.to_f
      end
      puts "cumulative_review_tone :: [#{cumulative_review_tone[0]}, #{cumulative_review_tone[1]}]"
    }
    puts "cumulative tone :: positive - #{cumulative_review_tone[0]}, negative - #{cumulative_review_tone[1]}"
    if(cumulative_review_tone[0] == 0 and cumulative_review_tone[1] == 0)
      cumulative_review_tone[2] = 1 #setting neutrality value
    else
      cumulative_review_tone[2] = 0
    end
    return cumulative_review_tone
  end 
#--------  
  def get_feature_vector(vertex, positive, negative, speller)    
    threshold = THRESHOLD #max distance at which synonyms can be searched
    feature_vector = Array.new #size of the array depends on th number of tone dimensions e.g.[positive, negative, netural]
    feature_vector = [0, 0] #initializing          
    #look for the presence of token in positive set
    puts "** checking positive"
    if(in_set(positive, vertex.name.downcase, speller))
      feature_vector[0] = 1 #
    else 
      #recursively check for synonyms of token in the positive set
      distance = 1
      flag = 0      
      synonym_sets = get_synonyms(vertex, threshold, speller) #gets upto 'threshold' levels of synonms in a double dimensional array
      synonym_sets.each{
        |set|  
        synonyms = set
        synonyms.each{
          |syn|
          if(in_set(positive, syn, speller))
            feature_vector[0] = 1/distance
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
    if(in_set(negative, vertex.name.downcase, speller))
      feature_vector[1] = 1 #
    else 
      #recursively check for synonyms of token in the positive set
      distance = 1
      flag = 0      
      synonym_sets = get_synonyms(vertex, threshold, speller) #gets upto 'threshold' levels of synonms in a double dimensional array
      if(!synonym_sets[1].empty?)#i.e. if there were no synonyms identified for the token avoid rechecking for [0] - since that contains the original token
        synonym_sets.each{
          |set|  
          synonyms = set
          synonyms.each{
            |syn|
            if(in_set(negative, syn, speller))
              feature_vector[1] = 1/distance
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
    return feature_vector
  end
#--------  
=begin
 Compares token with every word in the positive or negative opinion lexicon set 
=end
  def in_set(set, token, speller)
    wbsim = WordnetBasedSimilarity.new
    token_stem = wbsim.find_stem_word(token, speller)
    puts "***looking for #{token}..stem #{token_stem}"
    set.each{
      |ele|
      eleStem = wbsim.find_stem_word(ele, speller)
      #puts "comparing with #{ele.downcase}"
      if(ele.downcase == token or ele.downcase == token_stem or eleStem == token or eleStem == token_stem)
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

  def get_synonyms(vertex, threshold, speller)
    #puts "Inside getSynonyms"
    wbsim = WordnetBasedSimilarity.new
    pos = wbsim.determine_POS(vertex)
    
    revSyn = Array.new(threshold+1){Array.new} #contains synonyms for the different levels
    revSyn[0] << vertex.name.downcase #holds the array of tokens whose synonyms are to be identified
    #at first level '0' is the token itself
    i = 0
    while i < threshold do
      list_new = Array.new 
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
            review_lemma_synset = lemma.synsets[g]
            #synonyms
            rev_lemma_syns = review_lemma_synset.get_relation("&")
            #for each synset get the values and add them to the array
            for h in 0..rev_lemma_syns.length - 1
              list_new[0] = rev_lemma_syns[h].words
              #puts"revLemmaSyns[h].words #{revLemmaSyns[h].words} #{revLemmaSyns[h].words.class}"
            end
          end 
        end #end of checking if the lemma is nil or empty
        rescue
          puts "lemma doesn't have any synsets"
        end
      } #end of iterating through revSyn[level]'s tokens
      
      if(list_new.empty?)
        #puts "list_new is empty"
        break
      end
      puts "synonyms in level #{i} are #{list_new[0]}"
      i+=1 #level is incremented
      revSyn[i] = list_new[0] #setting synonyms
    end
    return revSyn
  end
  
end