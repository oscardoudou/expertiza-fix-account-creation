require 'Automated_Metareview/constants'
require 'Automated_Metareview/Edge'
require 'Automated_Metareview/vertex'

class TextCollection
=begin
  pre-processes the review text and sends it in for graph formation and further analysis
=end
def get_review(flag, text_array)
  if(flag == 0)
    reviews = Array.new(1){Array.new}
  else
    reviews = Array.new(50){Array.new} #50 is the number of different reviews/submissions
  end
  
  i = 0
  j = 0
  
  for k in (0..text_array.length-1)
    text = text_array[k]
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
    # text.gsub!(";", "")
    # text.gsub!(",", "")
    text.gsub!("(", "")
    text.gsub!(")", "")
    if(text.include?("http://"))
      text = remove_urls(text)
    end
    puts "text .. #{text}"      
    #break the text into multiple sentences
    beginn = 0
    if(text.include?(".") or text.include?("?") or text.include?("!") or text.include?(",") or text.include?(";") ) #new clause or sentence
      while(text.include?(".") or text.include?("?") or text.include?("!") or text.include?(",") or text.include?(";")) do #the text contains more than 1 sentence
        endd = 0
        #these 'if' conditions have to be independent, cause the value of 'endd' could change for the different types of punctuations
        if(text.include?("."))
          endd = text.index(".")
        end
        if((text.include?("?") and endd != 0 and endd > text.index("?")) or (text.include?("?") and endd == 0))#if a ? occurs before a .
          endd = text.index("?")
        end
        if((text.include?("!") and endd!= 0 and endd > text.index("!")) or (text.include?("!") and endd ==0))#if an ! occurs before a . or a ?
          endd = text.index("!")
        end
        if((text.include?(",") and endd != 0 and endd > text.index(",")) or (text.include?(",") and endd == 0)) #if a , occurs before any of . or ? or ! 
          endd = text.index(",")
        end
        if((text.include?(";") and endd != 0 and endd > text.index(";")) or (text.include?(";") and endd == 0)) #if a ; occurs before any of . or ?, ! or , 
          endd = text.index(";")
        end
              
        #check if the string between two commas or punctuations is there to buy time e.g. ", say," ",however," ", for instance, "... 
        if(flag == 0) #training
          reviews[0][i] = text[beginn..endd].strip
          #puts "reviews[0][i] #{reviews[0][i]}"
        else #testing
          reviews[j][i] = text[beginn..endd].strip
        end        
        i+=1 #incrementing the sentence counter
        text = text[(endd+1)..text.length] #from end+1 to the end of the string variable
      end #end of the while loop   
    else #if there is only 1 sentence in the text
      if(flag == 0)#training            
        reviews[0][i] = text.strip
        #puts "reviews[0][i] #{reviews[0][i]}"
        i+=1 #incrementing the sentence counter
      else #testing
        reviews[j][i] = text.strip
      end
    end
        
    # if(!text.empty?())#if text is not empty
      # if(flag == 0)#training
        # reviews[0][i] = text
        # #puts "reviews[0][i] #{reviews[0][i]}.. text #{text}"
        # i+=1
      # else #testing
        # reviews[j][i] = text
      # end
    # end
  
    if(flag == 1)#incrementing reviews counter only for test reviews
      j+=1
    end 
  end #end of the for loop with 'k' reading text rows
  
  #setting the number of reviews before returning
  if(flag == 0)#training
    num_reviews = 1 #for training the number of reviews is 1
  else #testing
    num_reviews = j
  end

  #puts "array inside textCollection #{reviews[0]}"
  if(flag == 0)
    return reviews[0]
  end
end
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
   * Reads the patterns from the csv file containing them. 
   * maxValue is the maximum value of the patterns found
=end

def read_patterns(filename, pos)
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
    
  #puts("**State is:: #{state}")
  FasterCSV.foreach(filename) do |text|
    #puts text
    in_vertex = text[0][0..text[0].index("=")-1].strip
    out_vertex = text[0][text[0].index("=")+2..text[0].length].strip

    first_string_in_vertex = pos.get_readable(in_vertex.split(" ")[0]) #getting the first token in vertex to determine POS
    first_string_out_vertex = pos.get_readable(out_vertex.split(" ")[0]) #getting the first token in vertex to determine POS
      
    #puts("invertex:: #{invertex} - outvertex:: #{outvertex}")
    #puts("firstStringInVertex:: #{firstStringInVertex} - firstStringOutVertex:: "+firstStringOutVertex);
    #puts("In-POS:: #{firstStringInVertex[firstStringInVertex.index("/")+1..firstStringInVertex.length-1]} - OutPOS:: #{firstStringOutVertex[firstStringOutVertex.index("/")+1..firstStringOutVertex.length-1]}")
      
     patterns[i] = Edge.new("noun", NOUN)
     #setting the invertex
     if(first_string_in_vertex.include?("/NN") or first_string_in_vertex.include?("/PRP") or first_string_in_vertex.include?("/IN") or first_string_in_vertex.include?("/EX") or first_string_in_vertex.include?("/WP"))
          patterns[i].in_vertex = Vertex.new(in_vertex, NOUN, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
     elsif(first_string_in_vertex.include?("/VB") or first_string_in_vertex.include?("MD"))
      patterns[i].in_vertex = Vertex.new(in_vertex, VERB, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
     elsif(first_string_in_vertex.include?("JJ"))
      patterns[i].in_vertex = Vertex.new(in_vertex, ADJ, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
     elsif(first_string_in_vertex.include?("/RB"))
      patterns[i].in_vertex = Vertex.new(in_vertex, ADV, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length]) 
     else #default to noun
      patterns[i].in_vertex = Vertex.new(in_vertex, NOUN, i, state, nil, nil, first_string_in_vertex[first_string_in_vertex.index("/")+1..first_string_in_vertex.length])
     end      
     
     #setting outvertex
     if(first_string_out_vertex.include?("/NN") or first_string_out_vertex.include?("/PRP") or first_string_out_vertex.include?("/IN") or first_string_out_vertex.include?("/EX") or first_string_out_vertex.include?("/WP"))
      patterns[i].out_vertex = Vertex.new(out_vertex, NOUN, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])
     elsif(first_string_out_vertex.include?("/VB") or first_string_out_vertex.include?("MD"))
      patterns[i].out_vertex = Vertex.new(out_vertex, VERB, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])
     elsif(first_string_out_vertex.include?("JJ"))
      patterns[i].out_vertex = Vertex.new(out_vertex, ADJ, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length-1]);
     elsif(first_string_out_vertex.include?("/RB"))
      patterns[i].out_vertex = Vertex.new(out_vertex, ADV, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])  
    else #default is noun
      patterns[i].out_vertex = Vertex.new(out_vertex, NOUN, i, state, nil, nil, first_string_out_vertex[first_string_out_vertex.index("/")+1..first_string_out_vertex.length])
    end
    #puts("Pattern:: #{patterns[i].in_vertex.name} - #{patterns[i].out_vertex.name}")
    i+=1 #incrementing for each pattern 
  end #end of the FasterCSV.foreach loop
  num_patterns = i
  #puts("num_patterns:: #{num_patterns}")
  return patterns
end

#------------------------------------------#------------------------------------------#------------------------------------------

=begin
 Removes any urls in the text and returns the remaining text as it is 
=end
def remove_urls(text)
  final_text = String.new
  if(text.include?("http://"))
    tokens = text.split(" ")
    tokens.each{
      |token|
      if(!token.include?("http://"))
        final_text = final_text + " " + token
      end  
    }
  else
    return text
  end
  #puts "final_text - #{final_text}"
  return final_text  
end
#------------------------------------------#------------------------------------------#------------------------------------------

end #end of class

#testing
# tc = TextCollection.new
# tc.getReview(1, "/Users/lakshmi/Documents/Thesis/Ruby-test/content-patterns/Expertiza-full-patterns/assess.csv")
#posTagger = EngTagger.new
#tc.readPatterns("/Users/lakshmi/Documents/Thesis/Ruby-test/content-patterns/Expertiza-full-patterns/patterns-assess.csv", posTagger)
