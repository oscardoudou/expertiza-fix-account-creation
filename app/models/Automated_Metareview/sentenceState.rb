require 'Automated_Metareview/negations'

class SentenceState
  POSITIVE = 0
  SUGGESTIVE = 1
  NEGATED = 2  
  NEGATIVE_WORD = 3
  NEGATIVE_DESCRIPTOR = 4
  NEGATIVE_PHRASE = 5
  MAX = 10
  @brokenSentences = nil
  
  def identifySentenceState(strWithPosTags)
    puts("**** Inside identifySentenceState #{strWithPosTags}")
    #break the sentence at the co-ordinating conjunction
    numConjunctions = breakAtCoordinatingConjunctions(strWithPosTags)
    
    states_array = Array.new
    if(@brokenSentences == nil)#{//no co-ordinating conjunction
      states_array[0] = sentenceState(strWithPosTags)
    #identifying states for each of the sentence segments
    else
      for i in (0..numConjunctions)#(int i = 0; i < numConjunctions; i++){
        if(!@brokenSentences[i].nil?)#{
          puts("brokenSentences[i]:: #{@brokenSentences[i]}")
          states_array[i] = sentenceState(@brokenSentences[i])
        end
      end
    end
    #System.out.println("&&&&&&& Final State:: "+STATE);
    return states_array
  end #end of the methods
#------------------------------------------#------------------------------------------  
  def breakAtCoordinatingConjunctions(strWithPosTags)
    st = strWithPosTags.split(" ")
    count = st.length
    counter = 0

    @brokenSentences = Array.new
    #if the sentence contains a co-ordinating conjunction
    if(strWithPosTags.include?("CC"))#{// || strWithPosTags.contains("IN")
      #System.out.println("Found a co-ordinating conjunction!");
      counter = 0
      temp = ""
      for i in (0..count-1)#while(st.hasMoreTokens()){
        ps = st[i] #.nextToken();
        if(!ps.nil? and ps.include?("CC"))#{//|| ps.contains("IN") //token contains CC//&& !ps.substring(0, ps.indexOf("/")).equalsIgnoreCase("of")
          #System.out.println("Sentence segment:: "+temp);
          @brokenSentences[counter] = temp #for "run/NN on/IN..."
          counter+=1
          temp = ps[0..ps.index("/")]
          #the CC or IN goes as part of the following sentence
        elsif (!ps.nil? and !ps.include?("CC"))
          temp = temp +" "+ ps[0..ps.index("/")]
        end
      end
      if(!temp.empty?) #setting the last sentence segment
        @brokenSentences[counter] = temp
        counter+=1
      end
    else#{//if no co-ordinating conjunctions were found
      @brokenSentences[counter] = strWithPosTags
      counter+=1
    end
    return counter
  end #end of the method
#------------------------------------------#------------------------------------------

  #Checking if the token is a negative token
  def sentenceState(strWithPosTags)
    puts("***** Checking sentence state:: #{strWithPosTags}")
    #System.out.println("***** Checking sentence state::");
    state = POSITIVE
    #checking single tokens for negated words
    st = strWithPosTags.split(" ")
    count = st.length
    #System.out.println("Count:: "+count);
    tokens = Array.new
    taggedTokens = Array.new
    i = 0
    interimNOUNVERB  = false #0 indicates no interim nouns or verbs
        
    #fetching all the tokens
    for k in (0..st.length-1)
      ps = st[k]
      #setting the tagged string
      taggedTokens[i] = ps
      if(ps.include?("/"))
        ps = ps[0..ps.index("/")-1] 
      end
      #removing punctuations 
      if(ps.include?("."))
        tokens[i] = ps[0..ps.index(".")-1] #ps.replaceAll(".", "") - DOESNT WORK
      elsif(ps.include?(","))
        tokens[i] = ps.gsub(",", "")
      elsif(ps.include?("!"))
        tokens[i] = ps.gsub("!", "")
      elsif(ps.include?(";"))
        tokens[i] = ps.gsub(";", "")
      else
        tokens[i] = ps
        #System.out.println("tokens[i]:"+tokens[i]);
        i+=1
      end
    end#end of the for loop
    
    #iterating through the tokens to determine state
    prevNegativeWord =""
    for j  in (0..count-1) #(int j = 0; j < count; j++){
      puts("tokens[j]: #{tokens[j]}")
      #checking type of the word
      #checking for negated words
      if(isNegativeWord(tokens[j]) == NEGATED)  
        returnedType = NEGATIVE_WORD
      #checking for a negative descriptor (indirect indicators of negation)
      elsif(isNegativeDescriptor(tokens[j]) == NEGATED)
        returnedType = NEGATIVE_DESCRIPTOR
      #2-gram phrases of negative phrases
      elsif(j+1 < count && isNegativePhrase(tokens[j]+" "+tokens[j+1]) == NEGATED)
        returnedType = NEGATIVE_PHRASE
        j = j+1      
      #if suggestion word is found
      elsif(isSuggestive(tokens[j]) == SUGGESTIVE)
        returnedType = SUGGESTIVE;
      #2-gram phrases suggestion phrases
      elsif(j+1 < count && isSuggestivePhrase(tokens[j]+" "+tokens[j+1]) == SUGGESTIVE)
        returnedType = SUGGESTIVE
        j = j+1
      #else set to positive
      else
        returnedType = POSITIVE
      end
      
      #----------------------------------------------------------------------
      #comparing 'returnedType' with the existing STATE of the sentence clause
      #after returnedType is identified, check its state and compare it to the existing state
      
      puts("token:: "+tokens[j]+" returnedType:: #{returnedType} STATE:: #{state}")
      puts("prevNegativeWord:: #{prevNegativeWord}")
      
      #if an interim non-negative or non-suggestive word was found
      if(returnedType == POSITIVE)
        if(interimNOUNVERB == false and (taggedTokens[j].include?("NN") or taggedTokens[j].include?("PR") or taggedTokens[j].include?("VB") or taggedTokens[j].include?("MD")))
          interimNOUNVERB = true
        end
      end 
      
      if(state == POSITIVE and returnedType != POSITIVE)
        state = returnedType;
        #interimNOUNVERB = 0;//resetting
      #when state is a negative word
      elsif(state == NEGATIVE_WORD) #previous state
        if(returnedType == NEGATIVE_WORD)
          #these words embellish the negation, so only if the previous word was not one of them you make it positive
          if(prevNegativeWord.casecmp("NO") != 0 and prevNegativeWord.casecmp("NEVER") != 0 and prevNegativeWord.casecmp("NONE") != 0)
            state = POSITIVE #e.g: "not had no work..", "doesn't have no work..", "its not that it doesn't bother me..."
          else
            state = NEGATIVE_WORD #e.g: "no it doesn't help", "no there is no use for ..."
          end  
          interimNOUNVERB = false #resetting         
        elsif(returnedType == NEGATIVE_DESCRIPTOR or returnedType == NEGATIVE_PHRASE)
          state = POSITIVE #e.g.: "not bad", "not taken from", "I don't want nothing", "no code duplication"// ["It couldn't be more confusing.."- anomaly we dont handle this for now!]
          interimNOUNVERB = false #resetting
        elsif(returnedType == SUGGESTIVE)
          #e.g. " it is not too useful as people could...", what about this one?
          if(interimNOUNVERB == true) #there are some words in between
            state = NEGATIVE_WORD
          else
            state = SUGGESTIVE #e.g.:"I do not(-) suggest(S) ..."
          end
          interimNOUNVERB = false #resetting
        end
      #when state is a negative descriptor
      elsif(state == NEGATIVE_DESCRIPTOR)
        if(returnedType == NEGATIVE_WORD)
          if(interimNOUNVERB == true)#there are some words in between
            state = NEGATIVE_WORD #e.g: "hard(-) to understand none(-) of the comments"
          else
            state = POSITIVE #e.g."He hardly not...."
          end
          interimNOUNVERB = false #resetting
        elsif(returnedType == NEGATIVE_DESCRIPTOR)
          if(interimNOUNVERB == true)#there are some words in between
            state = NEGATIVE_DESCRIPTOR #e.g:"there is barely any code duplication"
          else 
            state = POSITIVE #e.g."It is hardly confusing..", but what about "it is a little confusing.."
          end
          interimNOUNVERB = false #resetting
        elsif(returnedType == NEGATIVE_PHRASE)
          if(interimNOUNVERB == true)#there are some words in between
            state = NEGATIVE_PHRASE #e.g:"there is barely any code duplication"
          else 
            state = POSITIVE #e.g.:"it is hard and appears to be taken from"
          end
          interimNOUNVERB = false #resetting
        elsif(returnedType == SUGGESTIVE)
          state = SUGGESTIVE #e.g.:"I hardly(-) suggested(S) ..."
          interimNOUNVERB = false #resetting
        end
      #when state is a negative phrase
      elsif(state == NEGATIVE_PHRASE)
        if(returnedType == NEGATIVE_WORD)
          if(interimNOUNVERB == true)#there are some words in between
            state = NEGATIVE_WORD #e.g."It is too short the text and doesn't"
          else
            state = POSITIVE #e.g."It is too short not to contain.."
          end
          interimNOUNVERB = false #resetting
        elsif(returnedType == NEGATIVE_DESCRIPTOR)
          state = NEGATIVE_DESCRIPTOR #e.g."It is too short barely covering..."
          interimNOUNVERB = false #resetting
        elsif(returnedType == NEGATIVE_PHRASE)
          state = NEGATIVE_PHRASE #e.g.:"it is too short, taken from ..."
          interimNOUNVERB = false #resetting
        elsif(returnedType == SUGGESTIVE)
          state = SUGGESTIVE #e.g.:"I too short and I suggest ..."
          interimNOUNVERB = false #resetting
        end
      #when state is suggestive
      elsif(state == SUGGESTIVE) #e.g.:"I might(S) not(-) suggest(S) ..."
        if(tokens[j].casecmp("not") == 0 or tokens[j].casecmp("n't") == 0) #e.g. "I could not..."
          state = NEGATIVE_WORD
        elsif(returnedType == NEGATIVE_DESCRIPTOR)
          state = NEGATIVE_DESCRIPTOR
        elsif(returnedType == NEGATIVE_PHRASE)
          state = NEGATIVE_PHRASE
        end
        #e.g.:"I suggest you don't.." -> suggestive
        interimNOUNVERB = false #resetting
      end
      
      #setting the prevNegativeWord
      if(tokens[j].casecmp("NO") == 0 or tokens[j].casecmp("NEVER") == 0 or tokens[j].casecmp("NONE") == 0)
        prevNegativeWord = tokens[j]
      end      
    end #end of for loop
    
    if(state == NEGATIVE_DESCRIPTOR or state == NEGATIVE_WORD or state == NEGATIVE_PHRASE)
      state = NEGATED
    end
    
    puts("*** Complete Sentence State:: #{state}")
    return state
  end
  
#------------------------------------------#------------------------------------------  

#Checking if the token is a negative token
def isNegativeWord(word)
  notNegated = POSITIVE
  for i in (0..NEGATED_WORDS.length - 1)
    #System.out.println("Comparing with "+NEGATED_WORDS[i]);
    if(word.casecmp(NEGATED_WORDS[i]) == 0)
      notNegated =  NEGATED #indicates negation found
      break
    end
  end
  #System.out.println("***isNegation:: "+word +" state:: "+notNegated);
  return notNegated
end
#------------------------------------------#------------------------------------------

#Checking if the token is a negative token
def isNegativeDescriptor(word)
  notNegated = POSITIVE
  for i in (0..NEGATIVE_DESCRIPTORS.length - 1)
    #System.out.println("Comparing with "+negations.NEGATIVE_DESCRIPTORS[i])
    if(word.casecmp(NEGATIVE_DESCRIPTORS[i]) == 0)
      notNegated =  NEGATED #indicates negation found
      break
    end  
  end
  #System.out.println("***isNegation:: "+word +" state:: "+notNegated);
  return notNegated
end

#------------------------------------------#------------------------------------------    

#Checking if the phrase is negative
def isNegativePhrase(phrase)
  notNegated = POSITIVE
  for i in (0..NEGATIVE_PHRASES.length - 1)
    #System.out.println("Comparing with "+NEGATED_WORDS[i]);
    if(phrase.casecmp(NEGATIVE_PHRASES[i]) == 0)
      notNegated =  NEGATED #indicates negation found
      break
    end
  end
  #System.out.println("***isNegation:: "+word +" state:: "+notNegated);
  return notNegated
end

#------------------------------------------#------------------------------------------    
#Checking if the token is a suggestive token
def isSuggestive(word)
  notSuggestive = POSITIVE
  for i in (0..SUGGESTIVE_WORDS.length - 1)
    #System.out.println("Comparing with "+negations.NEGATED_WORDS[i]);
    if(word.casecmp(SUGGESTIVE_WORDS[i]) == 0)
      notSuggestive =  SUGGESTIVE #indicates negation found
      break
    end
  end
  #System.out.println("***isSuggestive:: "+word +" state:: "+notSuggestive);
  return notSuggestive
end
#------------------------------------------#------------------------------------------

#Checking if the PHRASE is suggestive
def isSuggestivePhrase(phrase)
  notSuggestive = POSITIVE
  for i in (0..SUGGESTIVE_PHRASES.length - 1) #(int i = 0; i < suggestions.SUGGESTIVE_PHRASES.length; i++){
    if(phrase.casecmp(SUGGESTIVE_PHRASES[i]) == 0)
      notSuggestive =  SUGGESTIVE #indicates negation found
      break
    end
  end
  #System.out.println("***isNegation:: "+word +" state:: "+notNegated);
  return notSuggestive
end

#------------------------------------------#------------------------------------------      
end #end of the class

=begin
### Test code
posTagger = EngTagger.new
instance = SentenceState.new
taggedString = posTagger.get_readable("Alice had taken from the big fat cat.")
puts "taggedString:: #{taggedString}"
states = instance.identifySentenceState(taggedString)

for j in (0..states.length - 1)
  puts states[j]
end
=end