require 'Automated_Metareview/vertex'
require 'Automated_Metareview/constants'
require 'wordnet'

#initializing constants
NOMATCH = 0 #distinct
OVERLAPEXAM = 1 #overlapping examples
OVERLAPDEFIN = 1 #overlapping definitions
COMMONPARENTS = 2 #common parents
MERONYM = 3 #paraphrasing
HOLONYM = 3 #paraphrasing
HYPONYM = 4 #paraphrasing
HYPERNYM = 4 #paraphrasing
SYNONYM = 5 #paraphrasing
EXACT = 6 #exact strings
  
#negative matches
NEGOVERLAPEXAM = -1 #overlapping examples
NEGOVERLAPDEFIN = -1 #overlapping definitions
NEGCOMMONPARENTS = -2 #common parents
NEGMERONYM = -3 #paraphrasing
NEGHOLONYM = -3 #paraphrasing
NEGHYPONYM = -4 #paraphrasing
NEGHYPERNYM = -4 #paraphrasing
NEGSYNONYM = -5 #paraphrasing
ANTONYM = -5 #antonyms
NEGEXACT = -6 #exact strings
  
class WordnetBasedSimilarity
  @@posTagger = EngTagger.new  
  def compareStrings(reviewVertex, submVertex)
    #include WordNet
    WordNet::WordNetDB.path = "/usr/local/Cellar/wordnet/3.0"
    
    speller = Aspell.new("en_US")
    speller.suggestion_mode = Aspell::NORMAL
  
    review = reviewVertex.name
    submission = submVertex.name
    reviewState = reviewVertex.state
    submState = submVertex.state
    
    puts("@@@@@@@@@ Comparing Vertices:: #{review} and #{submission} :: RevState:: #{reviewState} and SubmState:: #{submState}");
    match = 0
    count = 0
    # lex = WordNet::Lexicon.new(WordNet::Lexicon::DEFAULT_DB_ENV, 0444)
    # synset = lex.lookup_synsets("play", WordNet::Noun, 1)
    # lex.close
    
    reviewPOS = ""
    submPOS = ""
       
    if(reviewVertex.name.casecmp(submVertex.name) == 0 and !isFrequentWord(reviewVertex.name))
      puts("Review vertex types #{reviewVertex.type} && #{submVertex.type}")   
      if(reviewState.equal?(submState) and reviewVertex.type.equal?(submVertex.type))
        match = match + EXACT
      elsif(!reviewState.equal?(submState) and reviewVertex.type.equal?(submVertex.type))
        match = match + NEGEXACT
      elsif(reviewState.equal?(submState) and !reviewVertex.type.equal?(submVertex.type))
        match = match + EXACT/2
      elsif(!reviewState.equal?(submState) and !reviewVertex.type.equal?(submVertex.type))
        match = match + NEGEXACT/2
      end
      puts("Found an exact match between vertices!")
      return EXACT
    end   
    
    stokRev = review.split(" ")
    #iterating through review tokens
    for i in (0..stokRev.length-1)
      revToken = stokRev[i].downcase()
      if(reviewPOS.empty?)#do not reset POS for every new token, it changes the POS of the vertex e.g. like has diff POS for vertices "like"(n) and "would like"(v)
        reviewPOS = determinePOS(reviewVertex)
      end
      
      puts("*** RevToken:: #{revToken} ::Review POS:: #{reviewPOS} class #{reviewPOS.class}")
      if(revToken.equal?("n't"))
        revToken = "not"
        puts("replacing n't")
      end
      
      #if the review token is a frequent word, continue
      if(isFrequentWord(revToken))
        puts("Skipping frequent word:: #{revToken}")
        next #equivalent of the "continue"
      end
      
      #depending on the type of POS, you open the corresponding index file
      if(reviewPOS == "n")
        # Open the index file for nouns
        revIndex = WordNet::NounIndex.instance
      elsif(reviewPOS == "v")
        revIndex = WordNet::VerbIndex.instance
      elsif(reviewPOS == "a")
        revIndex = WordNet::AdjectiveIndex.instance
      elsif(reviewPOS == "r")
        revIndex = WordNet::AdverbIndex.instance
      end
      puts "*** index #{revIndex}"
      #fetching synonyms, hypernyms, hyponyms etc. for the review token 
      
      revTok = []
      revTok << revToken
      revSyn =[]
      revHyper = []
      revHypo = []
      revMer = []
      revHol = []
      revGloss = []
      revAnt = []
      revExam = []
      revStem = []
      revStem << findStemWord(revToken, speller)
      
      reviewLemmas = WordNet::WordNetDB.find(revToken) #reviewLemma = revIndex.find(revToken) #
      if(reviewLemmas.nil?)
        reviewLemmas = WordNet::WordNetDB.find(revStem[0]) #revIndex.find(revStem[0])
      end
      #select the lemma corresponding to the token's POS
      reviewLemma = ""
      reviewLemmas.each do |l|
        puts "lemma's POS :: #{l.pos} and reviewPOS :: #{reviewPOS}"
        if(l.pos.casecmp(reviewPOS) == 0)
          reviewLemma = l
        end  
      end
      
      puts "Selected reviewLemma :: #{reviewLemma}"
      
      #error handling for lemmas's without synsets that throw errors! (likely due to the dictionary file we are using)
      begin #error handling
      #if selected reviewLemma is not nil or empty
      if(!reviewLemma.nil? and reviewLemma != "" and !reviewLemma.synsets.nil?)      
        #creating arrays of all the values for synonyms, hyponyms etc. for the review token
        for g in 0..reviewLemma.synsets.length - 1
          #fetching the first review synset
          reviewLemmaSynset = reviewLemma.synsets[g]
          revGloss << extractDefinition(reviewLemmaSynset.gloss)
          revExam << extractExamples(reviewLemmaSynset.gloss)
          
          #looking for all relations synonym, hypernym, hyponym etc. from among this synset
          #synonyms
          revLemmaSyns = reviewLemmaSynset.get_relation("&")
          #for each synset get the values and add them to the array
          for h in 0..revLemmaSyns.length - 1
            revSyn << revLemmaSyns[h].words
          end
          #hypernyms
          revLemmaHypers = reviewLemmaSynset.get_relation("@")#hypernym.words
          #for each synset get the values and add them to the array
          for h in 0..revLemmaHypers.length - 1
            revHyper << revLemmaHypers[h].words
          end
          #hyponyms
          revLemmaHypos = reviewLemmaSynset.get_relation("~")#hyponym
          #for each synset get the values and add them to the array
          for h in 0..revLemmaHypos.length - 1
            revHypo << revLemmaHypos[h].words
          end
          #meronym
          revLemmaMeros = reviewLemmaSynset.get_relation("%p")
          #for each synset get the values and add them to the array
          for h in 0..revLemmaMeros.length - 1
            revMer << revLemmaMeros[h].words
          end
          #holonyms
          revLemmaHolos = reviewLemmaSynset.get_relation("#p")
          #for each synset get the values and add them to the array
          for h in 0..revLemmaHolos.length - 1
            revHol << revLemmaHolos[h].words
          end
          #antonyms
          revLemmaAnts = reviewLemmaSynset.get_relation("!")
          #for each synset get the values and add them to the array
          for h in 0..revLemmaAnts.length - 1
            revAnt << revLemmaAnts[h].words
          end
        end  
        puts "reviewSynonyms:: #{revSyn}"
        puts "reviewHypernyms:: #{revHyper}"
        puts "reviewHyponyms:: #{revHypo}"
        puts "reviewMeronyms:: #{revMer}"
        puts "reviewHolonyms:: #{revHol}"
        puts "reviewAntonyms:: #{revAnt}" 
        puts "reviewGloss:: #{revGloss}" 
      end #end of checking if the lemma is nil or empty
      rescue
        puts "submLemma doesn't have any synsets"
      end
        
      stokSub = submission.split(" ")
      #iterating through submission tokens
      for i in (0..stokSub.length-1)
        subToken = stokSub[i].downcase()
        if(submPOS.empty?)#do not reset POS for every new token, it changes the POS of the vertex e.g. like has diff POS for vertices "like"(n) and "would like"(v)
          submPOS = determinePOS(submVertex)
        end
        
        puts("*** SubToken:: #{subToken} ::Review POS:: #{submPOS}")
        if(subToken.equal?("n't"))
          subToken = "not"
          puts("replacing n't")
        end
        
        #if the review token is a frequent word, continue
        if(isFrequentWord(subToken))
          puts("Skipping frequent word:: #{subToken}")
          next #equivalent of the "continue"
        end
        
        #fetching synonyms, hypernyms, hyponyms etc. for the review token    
        #depending on the type of POS, you open the corresponding index file
        if(submPOS == "n")
          # Open the index file for nouns
          submIndex = WordNet::NounIndex.instance
        elsif(submPOS == "v")
          submIndex = WordNet::VerbIndex.instance
        elsif(submPOS == "a")
          submIndex = WordNet::AdjectiveIndex.instance
        elsif(submPOS == "r")
          submIndex = WordNet::AdverbIndex.instance
        end
      
        #puts "*** index #{submIndex}"
        #fetching synonyms, hypernyms, hyponyms etc. for the submission token       
        submTok = []
        submTok << subToken
        submSyn =[]
        submHyper = []
        submHypo = []
        submMer = []
        submHol = []
        submGloss = []
        submExam = []
        submAnt = []
        submStem = []
        submStem << findStemWord(subToken, speller)
      
        submLemmas = WordNet::WordNetDB.find(subToken) #submIndex.find(subToken)
        if(submLemmas.nil?)
          submLemmas = WordNet::WordNetDB.find(submStem[0]) #submIndex.find(submStem[0])
        end
        #select the lemma corresponding to the token's POS
        submLemma = ""
        submLemmas.each do |l|
          if(l.pos.casecmp(submPOS) == 0)
            submLemma = l
          end  
        end 
        puts "Selected submLemma :: #{submLemma}"
        
        #error handling for lemmas's without synsets that throw errors! (likely due to the dictionary file we are using)
        begin #error handling       
        #when the lemma is not nil or empty
        if(!submLemma.nil? and (submLemma != "" and !submLemma.synsets.nil?))    
          #creating arrays of all the values for synonyms, hyponyms etc. for the review token
          for g in 0..submLemma.synsets.length - 1
            #fetching the first review synset
            submLemmaSynset = submLemma.synsets[g]
            submGloss << extractDefinition(submLemmaSynset.gloss)
            submExam << extractExamples(submLemmaSynset.gloss)
            #looking for all relations synonym, hypernym, hyponym etc. from among this synset
            #synonyms
            submLemmaSyns = submLemmaSynset.get_relation("&")
            #for each synset get the values and add them to the array
            for h in 0..submLemmaSyns.length - 1
              submSyn << submLemmaSyns[h].words
            end
            #hypernyms
            submLemmaHypers = submLemmaSynset.get_relation("@") #hypernym.words
            #for each synset get the values and add them to the array
            for h in 0..submLemmaHypers.length - 1
              submHyper << submLemmaHypers[h].words
            end
            #hyponyms
            submLemmaHypos = submLemmaSynset.get_relation("~")#hyponym
            #for each synset get the values and add them to the array
            for h in 0..submLemmaHypos.length - 1
              submHypo << submLemmaHypos[h].words
            end
            #meronym
            submLemmaMeros = submLemmaSynset.get_relation("%p")
            #for each synset get the values and add them to the array
            for h in 0..submLemmaMeros.length - 1
              submMer << submLemmaMeros[h].words
            end
            #holonyms
            submLemmaHolos = submLemmaSynset.get_relation("#p")
            #for each synset get the values and add them to the array
            for h in 0..submLemmaHolos.length - 1
              submHol << submLemmaHolos[h].words
            end
            #antonyms
            submLemmaAnts = submLemmaSynset.get_relation("!")
            #for each synset get the values and add them to the array
            for h in 0..submLemmaAnts.length - 1
              submAnt << submLemmaAnts[h].words
            end
          end  #end of for loop for the lemma's synsets
          puts "submSynonyms:: #{submSyn}"
          puts "submHypernyms:: #{submHyper}"
          puts "submHyponyms:: #{submHypo}"
          puts "submMeronyms:: #{submMer}"
          puts "submHolonyms:: #{submHol}"
          puts "submAntonyms:: #{submAnt}" 
          puts "submGloss:: #{submGloss}" 
          # puts "submStem:: #{submStem}"  
        end #of if condition for an empty or nil lemma       
        rescue
          puts "submLemma doesn't have any synsets"
        end
        #------------------------------------------
        #checks are ordered from BEST to LEAST degree of semantic relatedness
        #*****exact matches        
        if(subToken.casecmp(revToken) == 0 or submStem[0].casecmp(revStem[0]) == 0) #EXACT MATCH (submission.toLowerCase().equals(review.toLowerCase()))
          puts("exact match for #{revToken} & #{subToken} or #{submStem[0]} and #{revStem[0]}")
          if(reviewState.equal?(submState) and reviewPOS.equal?(submPOS))
            match = match + EXACT
          elsif(!reviewState.equal?(submState) and reviewPOS.equal?(submPOS))
            match = match + NEGEXACT
          elsif(reviewState.equal?(submState) and !reviewPOS.equal?(submPOS))
            match = match + EXACT/2
          elsif(!reviewState.equal?(submState) and !reviewPOS.equal?(submPOS))
            match = match + NEGEXACT/2
          end
          count+=1
          next #skip all remaining checks
        end #end of if condition checking for exact matches
        #------------------------------------------
        #*****For Synonyms
        #checking if any of the review token's synonyms match with the subm. token or its stem form
        #submTok is an array containing the subToken, this is to help with comparing arrays, similarly with revTok
          if((!revSyn.nil? and !submSyn.nil? and (revSyn & submSyn).length > 0) or (!revSyn.nil? and ((revSyn & submTok).length > 0 or (revSyn & submStem).length > 0)) or 
            (!submSyn.nil? and ((submSyn & revTok).length > 0 or (submSyn & revStem).length > 0)))          
            puts("Synonym found between: #{revToken} & #{subToken}")
            if(reviewState == submState && reviewPOS == submPOS)
              match = match + SYNONYM
            elsif(reviewState != submState && reviewPOS == submPOS)
              match = match + NEGSYNONYM
            elsif(reviewState == submState && reviewPOS != submPOS)
              match = match + SYNONYM/2
            elsif(reviewState != submState && reviewPOS != submPOS)
              match = match + NEGSYNONYM/2
            end
            puts("@@ Match: #{match}")
            count+=1
            next
          end
        #------------------------------------------
         #ANTONYMS
        #Checking if the submission token appears in the review's set of antonyms or if review token appears in the submission's set of antonyms
        if((!revAnt.nil? and !submAnt.nil? and (revAnt & submAnt).length > 0) or (!revAnt.nil? and ((revAnt & submTok).length > 0 or (revAnt & submStem).length > 0)) or 
          (!submAnt.nil? and ((submAnt & revTok).length > 0 or (submAnt & revStem).length > 0))) #listRevArr.toString(), subToken.toLowerCase()))){
            if(reviewState == submState && reviewPOS == submPOS)
              match = match + ANTONYM
              puts("Antonyms found: #{revToken} and #{subToken}");
            elsif(reviewState != submState && reviewPOS == submPOS)
              match = match + SYNONYM;
              puts("(-)(-) Synonym found: #{revToken} and #{subToken}")
            elsif(reviewState == submState && reviewPOS != submPOS)
              match = match + ANTONYM/2
              puts("Antonyms with diff POS: #{revToken} and #{subToken}")
            elsif(reviewState != submState && reviewPOS != submPOS)
              match = match + SYNONYM/2
              puts("(-)(-) Synonym with diff POS: #{revToken} and #{subToken}")
            end
            count+=1
            next
        end
        #------------------------------------------
        #*****For Hypernyms
        #checking if any of the review token's synonyms match with the subm. token or its stem form
          if((!revHyper.nil? and !submHyper.nil? and (revHyper & submHyper).length > 0) or (!revHyper.nil? and ((revHyper & submTok).length > 0 or (revHyper & submStem).length > 0)) or 
            (!submHyper.nil? and ((submHyper & revTok).length > 0 or (submHyper & revStem).length > 0)))          
            puts("Hypernym found between: #{revToken} & #{subToken}")
            if(reviewState == submState)
              match = match + HYPERNYM
            elsif(reviewState != submState)
              match = match + NEGHYPERNYM
            end
            puts("@@ Match: #{match}")
            count+=1
            next
          end
        #------------------------------------------   
        #*****For Hyponyms
        #checking if any of the review token's synonyms match with the subm. token or its stem form
          if((!revHypo.nil? and !submHypo.nil? and (revHypo & submHypo).length > 0) or (!revHypo.nil? and ((revHypo & submTok).length > 0 or (revHypo & submStem).length > 0)) or 
            (!submHypo.nil? and ((submHypo & revTok).length > 0 or (submHypo & revStem).length > 0)))          
            puts("Hyponym found between: #{revToken} & #{subToken}")
            if(reviewState == submState)
              match = match + HYPONYM
            elsif(reviewState != submState)
              match = match + NEGHYPONYM
            end
            puts("@@ Match: #{match}")
            count+=1
            next
          end
        #------------------------------------------
        #*****For Meronyms
        #checking if any of the review token's synonyms match with the subm. token or its stem form
          if((!revMer.nil? and !submMer.nil? and (revMer & submMer).length > 0) or (!revMer.nil? and ((revMer & submTok).length > 0 or (revMer & submStem).length > 0)) or 
            (!submMer.nil? and ((submMer & revTok).length > 0 or (submMer & revStem).length > 0)))          
            puts("Meronym found between: #{revToken} & #{subToken}")
            if(reviewState == submState)
              match = match + MERONYM
            elsif(reviewState != submState)
              match = match + NEGMERONYM
            end
            puts("@@ Match: #{match}")
            count+=1
            next
          end
        #------------------------------------------
        #*****For Holonyms
        #checking if any of the review token's synonyms match with the subm. token or its stem form
          if((!revHol.nil? and !submHol.nil? and (revHol & submHol).length > 0) or (!revHol.nil? and ((revHol & submTok).length > 0 or (revHol & submStem).length > 0)) or 
            (!submHol.nil? and ((submHol & revTok).length > 0 or (submHol & revStem).length > 0)))          
            puts("Meronym found between: #{revToken} & #{subToken}")
            if(reviewState == submState)
              match = match + HOLONYM
            elsif(reviewState != submState)
              match = match + NEGHOLONYM
            end
            puts("@@ Match: #{match}")
            count+=1
            next
          end
        #------------------------------------------ 
        #*****For COMMON PARENTS
        
        #------------------------------------------ 
        #overlap across definitions   
        if(!revGloss.nil? and !submGloss.nil?)
          if(overlap(revGloss, submGloss) > 0)
            if(reviewState == submState)
              match = match + OVERLAPDEFIN
            elsif(reviewState != submState)
              match = match + NEGOVERLAPDEFIN
            end
            count+=1
            next
          end
        end
        #------------------------------------------
        #overlap across examples
        if(!revExam.nil? and !submExam.nil?)
          if(overlap(revExam, submExam) > 0)
            if(reviewState == submState)
              match = match + OVERLAPEXAM
            elsif(reviewState != submState)
              match = match + NEGOVERLAPEXAM
            end
            count+=1
            next
          end
        end
        #------------------------------------------  
        #no match found!
        puts "No Match found!"
        match = match + NOMATCH
        count+=1
      end #end of the for loop for submission tokens    
    end #end of the for loop for review tokens
    
    if(count > 0)
      puts ("Match: #{match} Count:: #{count}")
      puts("@@@@@@@@@ Returning Value: #{(match.to_f/count.to_f).round}")
      return (match.to_f/count.to_f).round #an average of the matches found
    end
    puts("@@@@@@@@@ Returning NOMATCH")
    return NOMATCH
    
  end #end of compareStrings method
  
#------------------------------------------------------------------------------
#distance between the two concepts (synsets)
def distance(syn1, syn2)#using wu and palmer (2 * depth(syn1, syn2)/depth(syn1) + depth(syn2))  
  #locating common parent for the two synsets
  
  puts "numOverlap #{numOverlap}"
  return numOverlap
end
#------------------------------------------------------------------------------

=begin
 determinePOS - method helps identify the POS tag (for the wordnet lexicon) for a certain word 
=end
def determinePOS(vert)
  str_pos = vert.posTag
  #puts("Inside determinePOS POS Tag:: #{str_pos}")
  if(str_pos.include?("CD") or str_pos.include?("NN") or str_pos.include?("PR") or str_pos.include?("IN") or str_pos.include?("EX") or str_pos.include?("WP"))
    pos = "n"#WordNet::Noun
  elsif(str_pos.include?("JJ"))
    pos = "a" #WordNet::Adjective
  elsif(str_pos.include?("TO") or str_pos.include?("VB") or str_pos.include?("MD"))
    pos = "v" #WordNet::Verb
  elsif(str_pos.include?("RB"))
    pos = "r" #WordNet::Adverb
  else
    pos = "n" #WordNet::Noun
  end
  #puts("Part of Speech:: #{pos}")
  return pos
end
#------------------------------------------------------------------------------  
=begin
 'isStopWord' method checks to see if the word is a stop word or frequently used word  
=end
def isStopWord(word)
  #constants con = new constants();
  #removing any (, ), [, ] in the string 
  word.gsub!("(", "") #gsub replaces all occurrences of "(" and the exclamation point helps to do in-place substitution
  word.gsub!(")", "") #if the character doesn't exist, the function returns nil, which does not affect the existing variable
  word.gsub!("[", "")
  word.gsub!("]", "")
  word.gsub!("\"", "")
  
  #checking for closed class words
  for i in (0..CLOSED_CLASS_WORDS.length-1) #(int i = 0; i < constants.CLOSED_CLASS_WORDS.length; i++)
    if(word.casecmp(CLOSED_CLASS_WORDS[i]) == 0)
      return true
    end
  end      
  
  #checking for stopwords
  for i in (0..STOP_WORDS.length-1) #(int i = 0; i < constants.STOP_WORDS.length; i++)
    if(word.casecmp(STOP_WORDS[i]) == 0)
      return true
    end    
    return false    
  end
end
#------------------------------------------------------------------------------      
=begin
  isFrequentWord - method checks to see if the given word is a frequent word
=end
def isFrequentWord(word)
  #checking if the word is a frequent word
  for i in (0..FREQUENT_WORDS.length-1)
    #puts FREQUENT_WORDS[i]
    if(word.casecmp(FREQUENT_WORDS[i]) == 0)
      return true
    end
  end
  return false
end #end of isFrequentWord method
#------------------------------------------------------------------------------
=begin
  findStemWord - stems the word and checks if the word is correctly spelt, else it will return a correctly spelled word as suggested by spellcheck
  It generated the nearest stem, since no context information is involved, the quality of the stems may not be great!
=end
def findStemWord(word, speller)
  stem = word.stem
  #puts "stem inside findStemWord #{stem}"
  
  correct = stem #initializing correct to the stem word
  #checkiing the stem word's spelling for correctness
  while(!speller.check(correct)) do
    if(!speller.suggest(correct).first.nil?)
      correct = speller.suggest(correct).first
    else
      #break out of the loop, else it will continue infinitely
      break #break out of the loop if the first correction was nil
    end
  end
  #puts "**** stem for #{word} is #{correct}"  
  return correct
end #end of isFrequentWord method

end #end of WordnetBasedSimilarity class

#------------------------------------------------------------------------------
=begin
 This method is used to extract definitions for the words (since glossed contain definitions and examples!)
 glosses - string containing the gloss of the synset 
=end
def extractDefinition(glosses)
  #puts "***** Inside extractDefinition"
  definitions = []
  #extracting examples from definitions
  temp = glosses
  tempList = temp.split(";")
  for i in 0..tempList.length - 1
    if(!tempList[i].include?('"'))
      definitions << tempList[i]
    end
  end
  #puts definitions
  return definitions
end

#------------------------------------------------------------------------------
def extractExamples(glosses) #glosses is a single gloss with possibly many examples
  #puts "***** Inside extractExamples"
  examples = []  
  #extracting examples from definitions
  temp = glosses
  tempList = temp.split(";")
  for i in 0..tempList.length - 1
    #puts " printing #{tempList[i]}"
    if(tempList[i].include?('"'))
      examples << tempList[i]
    end
  end
  #puts examples
  return examples
end

#------------------------------------------------------------------------------

def overlap(def1, def2)
  instance = WordnetBasedSimilarity.new
  numOverlap = 0
  #only overlaps across the ALL definitions
  #puts "def1.length #{def1.length}"
  #puts "def2.length #{def2.length}"
  
  #iterating through def1's definitions
  for i in 0..def1.length-1
    if(!def1[i][0].nil?)
      def1[i][0].gsub!("\"", " ")
      if(def1[i][0].include?(";"))
        def1[i][0] = def1[i][0][0..def1[i].index(";")]
      end
      #iterating through def2's definitions
      for j in 0..def2.length - 1   
        if(!def2[j][0].nil?)
          if(def2[j][0].include?(";"))
            def2[j][0] = def2[j][0][0..def2[j].index(";")]
          end
          
          s1 = def1[i][0].split(" ")
          s1.each do |tok1|
            s2 = def2[j][0].split(" ")
            s2.each do |tok2|
              if(tok1.casecmp(tok2) == 0 and instance.isStopWord(tok1) == false)
                puts("**Overlap def/ex:: #{tok1}")
                numOverlap+=1
              end
            end #end of s2 loop
          end #end of s1 loop
        end #end of def2[j][0] being null
      end #end of for loop for def2 - j
    end #end of if def1[i][0] being null
  end #end of for loop for def1 - i
  puts "numOverlap #{numOverlap}"
  return numOverlap
end
#------------------------------------------------------------------------------
    
# instance = WordnetBasedSimilarity.new
# v1 =  Vertex.new("version-control", 1, 1, 0, 1, 1, "NN")
# v2 =  Vertex.new("gives", 1, 1, 0, 1, 1, "JJ")
# instance.compareStrings(v1, v2)

#puts "vertex name #{instance.name}"
#puts instance.isStopWord("that")

# instance.findStemWord("fallacies")
# instance.findStemWord("plagued")
# instance.findStemWord("played")
# instance.findStemWord("playful")
# instance.findStemWord("running")

#puts instance.isStopWord("hello")
# index = WordNet::NounIndex.instance
# lemma = index.find("presentation")
# syns = lemma.synsets
# glo1 = syns[1].gloss
# glo2 = syns[2].gloss
# puts glo1
# puts glo2
# overlap(extractDefinition(glo1),extractDefinition(glo2)) 
#extractExamples(glo)


# def readFileAndWrite (filename)
  # words1 = []
  # words2 = []
  # results = []
#   
  # instance = WordnetBasedSimilarity.new
  # #reading the words
  # FasterCSV.foreach(filename) do |row|
    # puts row[0]
    # text = row[0].to_s
    # word1 = text[0..text.index("-")-2] 
    # word2 = text[text.index("-")+2..text.length-1]
    # puts "words - #{word1} && #{word2}"
    # words1 << word1
    # words2 << word2
    # v1 = Vertex.new(word1, 1, 1, 0, 1, 1, "NN")
    # v2 = Vertex.new(word2, 1, 1, 0, 1, 1, "NN")
    # results << instance.compareStrings(v1, v2)
  # end
#   
  # #writing results to a file
  # FasterCSV.open("/Users/lakshmi/Documents/Thesis/wordsim353-ruby/set4_353_results.csv", "w") do |csvWriter|
    # for i in 0..words1.length - 1
      # puts "#{words1[i]} - #{words2[i]} :: #{results[i]}"
      # csvWriter << [words1[i], words2[i], results[i]]
    # end
  # end
# end
# require 'faster_csv'
# readFileAndWrite("/Users/lakshmi/Documents/Thesis/wordsim353-ruby/set4_353_test.csv")





