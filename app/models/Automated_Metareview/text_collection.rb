# require 'faster_csv'

class TextCollection
  SIM_MATCH = 5
  NumClasses = 1
  SENTENCES = 100  #assuming each review has upto 5 sentences max.
  MAX = 3000
    
  @@numReviews = 0
  @@numPatterns = 0

=begin
  pre-processes the review text and sends it in for graph formation and further analysis
=end
def getReview(flag, textArray)
  if(flag == 0)
    reviews = Array.new(1){Array.new}
  else
    reviews = Array.new(50){Array.new} #50 is the number of different reviews/submissions
  end
  
  i = 0
  j = 0
  
  #puts "textArray.length #{textArray.length}"
  for k in (0..textArray.length-1)
    text = textArray[k]
    #puts "textArray[k] #{textArray[k]}"
    #puts("Text:: #{text.class} - #{text}")
    if(flag == 1) #reset i (the sentence counter) to 0 for test reviews
      reviews[j] = Array.new #initializing the array for sentences in a test review
      i = 0
    end
    #******* Pre-processing the review text **********
    #replacing commas in large numbers, makes parsing sentences with commas confusing!
    #replacing quotation marks
    text.gsub!("\"", "")
    text.gsub!(";", "")
    text.gsub!(",", "")
    text.gsub!("(", "")
    text.gsub!(")", "")
    #System.out.println("###### "+text);
          
    #break the text into multiple sentences
    beginn = 0
    if(text.include?(".") or text.include?("?") or text.include?("!") or text.include?(",") or text.include?(";") ) #new clause or sentence
      while(text.include?(".") or text.include?("?") or text.include?("!") or text.include?(",") or text.include?(";")) do #the text contains more than 1 sentence
        endd = 0
        if(text.include?("."))
          endd = text.index(".")
        elsif((text.include?("?") and endd != 0 and endd > text.index("?")) or (text.include?("?") and endd == 0))#if a ? occurs before a .
          endd = text.index("?")
        elsif((text.include?("!") and endd!= 0 and endd > text.index("!")) or (text.include?("!") and endd ==0))#if an ! occurs before a . or a ?
          endd = text.index("!")
        elsif((text.include?(",") and endd != 0 and endd > text.index(",")) or (text.include?(",") and endd == 0)) #if a , occurs before any of . or ? or ! 
          endd = text.index(",")
        elsif((text.include?(";") and endd != 0 and endd > text.index(";")) or (text.include?(";") and endd == 0)) #if a ; occurs before any of . or ?, ! or , 
          endd = text.index(";")
        end
              
        #check if the string between two commas or punctuations is there to buy time e.g. ", say," ",however," ", for instance, "... 
        if(flag == 0) #training
          reviews[0][i] = text[beginn..endd]
          #puts "reviews[0][i] #{reviews[0][i]}.. text[beginn..endd] #{text[beginn..endd]}"
        else #testing
          reviews[j][i] = text[beginn..endd]
        end
        
        i+=1 #incrementing the sentence counter
        text = text[(endd+1)..text.length] #from end+1 to the end of the string variable
        #System.out.println("Remaining txt:"+text);            
      end #end of the while loop   
    else #if there is only 1 sentence in the text
      if(flag == 0)#training            
        reviews[0][i] = text
        #puts "reviews[0][i] #{reviews[0][i]}..text #{text}"
        i+=1 #incrementing the sentence counter
      else #testing
        reviews[j][i] = text
      end
    end
        
    if(!text.empty?())#if text is not empty
      if(flag == 0)#training
        reviews[0][i] = text
        #puts "reviews[0][i] #{reviews[0][i]}.. text #{text}"
        i+=1
      else #testing
        reviews[j][i] = text
      end
    end
  
    if(flag == 1)#incrementing reviews counter only for test reviews
      j+=1
    end 
  end #end of the for loop with 'k' reading text rows
  
  #setting the number of reviews before returning
  if(flag == 0)#training
    numReviews = 1 #for training the number of reviews is 1
  else #testing
    numReviews = j
  end
  if(flag == 0)  
    puts("******* Number of sentences:: #{i}...reviews.length - #{reviews.length}..reviews[0].length - #{reviews[0].length}")
  end
  puts "review array (inside textCollection) #{reviews[0]}"
  if(flag == 0)
    return reviews[0]
  end
end
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
   * Reads the patterns from the csv file containing them. 
   * maxValue is the maximum value of the patterns found
=end

def readPatterns(filename,pos)
  num = 1000 #some large number
  patterns = Array.new
  state = POSITIVE
  i = 0 #keeps track of the number of edges
  
  #setting the state for problem detection and suggestive patterns
  if(filename.include?("prob"))
      state = NEGATED
  elsif(filename.include?("suggest"))
      state = SUGGESTIVE
  end
    
  puts("**State is:: #{state}")
  FasterCSV.foreach(filename) do |text|
    puts text
    invertex = text[0][0..text[0].index("=")-1]
    outvertex = text[0][text[0].index("=")+2..text[0].length]

    firstStringInVertex = pos.get_readable(invertex.split(" ")[0]) #getting the first token in vertex to determine POS
    firstStringOutVertex = pos.get_readable(outvertex.split(" ")[0]) #getting the first token in vertex to determine POS
      
    #puts("invertex:: #{invertex} - outvertex:: #{outvertex}")
    #puts("firstStringInVertex:: #{firstStringInVertex} - firstStringOutVertex:: "+firstStringOutVertex);
    puts("In-POS:: #{firstStringInVertex[firstStringInVertex.index("/")+1..firstStringInVertex.length-1]} - OutPOS:: #{firstStringOutVertex[firstStringOutVertex.index("/")+1..firstStringOutVertex.length-1]}")
      
     patterns[i] = Edge.new("noun", NOUN)
     #setting the invertex
     if(firstStringInVertex.include?("/NN") or firstStringInVertex.include?("/PRP") or firstStringInVertex.include?("/IN") or firstStringInVertex.include?("/EX") or firstStringInVertex.include?("/WP"))
          patterns[i].inVertex = Vertex.new(invertex, NOUN, i, state, nil, nil, firstStringInVertex[firstStringInVertex.index("/")+1..firstStringInVertex.length])
     elsif(firstStringInVertex.include?("/VB") or firstStringInVertex.include?("MD"))
      #System.out.println("IN verb")
      patterns[i].inVertex = Vertex.new(invertex, VERB, i, state, nil, nil, firstStringInVertex[firstStringInVertex.index("/")+1..firstStringInVertex.length])
      #System.out.println("patterns[i].inVertex.name"+patterns[i].inVertex.name);
     elsif(firstStringInVertex.include?("JJ"))
      patterns[i].inVertex = Vertex.new(invertex, ADJ, i, state, nil, nil, firstStringInVertex[firstStringInVertex.index("/")+1..firstStringInVertex.length])
     elsif(firstStringInVertex.include?("/RB"))
      patterns[i].inVertex = Vertex.new(invertex, ADV, i, state, nil, nil, firstStringInVertex[firstStringInVertex.index("/")+1..firstStringInVertex.length]) 
     else #default to noun
      #System.out.println("IN adverb");
      patterns[i].inVertex = Vertex.new(invertex, NOUN, i, state, nil, nil, firstStringInVertex[firstStringInVertex.index("/")+1..firstStringInVertex.length])
     end      
     
     #setting outvertex
     if(firstStringOutVertex.include?("/NN") or firstStringOutVertex.include?("/PRP") or firstStringOutVertex.include?("/IN") or firstStringOutVertex.include?("/EX") or firstStringOutVertex.include?("/WP"))
      patterns[i].outVertex = Vertex.new(outvertex, NOUN, i, state, nil, nil, firstStringOutVertex[firstStringOutVertex.index("/")+1..firstStringOutVertex.length])
     elsif(firstStringOutVertex.include?("/VB") or firstStringOutVertex.include?("MD"))
      patterns[i].outVertex = Vertex.new(outvertex, VERB, i, state, nil, nil, firstStringOutVertex[firstStringOutVertex.index("/")+1..firstStringOutVertex.length])
     elsif(firstStringOutVertex.include?("JJ"))
      patterns[i].outVertex = Vertex.new(outvertex, ADJ, i, state, nil, nil, firstStringOutVertex[firstStringOutVertex.index("/")+1..firstStringOutVertex.length-1]);
     elsif(firstStringOutVertex.include?("/RB"))
      puts("OUT adverb")
      patterns[i].outVertex = Vertex.new(outvertex, ADV, i, state, nil, nil, firstStringOutVertex[firstStringOutVertex.index("/")+1..firstStringOutVertex.length])
      #puts("patterns[i].outVertex.name #{patterns[i].outVertex.name}")  
    else #default is noun
      #System.out.println("OUT default");
      patterns[i].outVertex = Vertex.new(outvertex, NOUN, i, state, nil, nil, firstStringOutVertex[firstStringOutVertex.index("/")+1..firstStringOutVertex.length])
    end
    puts("Pattern:: #{patterns[i].inVertex.name} - #{patterns[i].outVertex.name}")
    i+=1 #incrementing for each pattern 
  end #end of the FasterCSV.foreach loop
  numPatterns = i
  puts("NumPatterns:: #{numPatterns}")
  return patterns
end
end
#------------------------------------------#------------------------------------------#------------------------------------------
#testing
# tc = TextCollection.new
# tc.getReview(1, "/Users/lakshmi/Documents/Thesis/Ruby-test/content-patterns/Expertiza-full-patterns/assess.csv")
#posTagger = EngTagger.new
#tc.readPatterns("/Users/lakshmi/Documents/Thesis/Ruby-test/content-patterns/Expertiza-full-patterns/patterns-assess.csv", posTagger)
