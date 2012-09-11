require 'Automated_Metareview/text_collection'
require 'Automated_Metareview/constants'
require 'Automated_Metareview/graph_generator'
#require 'faster_csv'

class PlagiarismChecker
=begin
 reviewText and submText are array containing review and submission texts 
=end
def check_for_plagiarism(review_text, subm_text)
  review_text = remove_text_within_quotes(review_text) #review_text is an array
  result = false
  for l in 0..review_text.length - 1 #iterating through the review's sentences
    review = review_text[l].to_s
    puts "review.class #{review.to_s.class}.. review - #{review}"
    for m in 0..subm_text.length - 1 #iterating though the submission's sentences
      submission = subm_text[m].to_s  
      puts "submission.class #{submission.to_s.class}..submission - #{submission}"
      rev_len = 0
      
      rev = review.split(" ") #review's tokens, taking 'n' at a time
      array = review.split(" ")
      
      while(rev_len < array.length) do
        if(array[rev_len] == " ") #skipping empty
          puts "skipping empty string: "
          rev_len+=1
          next
        end
        
        #generating the sentence segment you'd like to compare
        rev_phrase = array[rev_len]
       
        add = 0 #add on to this when empty strings found  
        
        for j in rev_len+1..(NGRAM+rev_len+add-1) #concatenating 'n' tokens
          #puts "array[j] #{array[j]}, j #{j}"
          if(j < array.length)
            if(array[j] == "") #skipping empty
              puts("skipping empty string: ")
              add+=1
              next
            end
            rev_phrase = rev_phrase +" "+  array[j]
          end
        end
        
        if(j == array.length)
          #if j has reached the end of the array, then reset rev_len to the end of array to, or shorter strings will be compared
          rev_len = array.length
        end
        
        #replacing punctuation
        graph_inst = GraphGenerator.new
        submission = graph_inst.contains_punct(submission)
        rev_phrase = graph_inst.contains_punct(rev_phrase)
        #puts "Review phrase: #{rev_phrase} .. #{rev_phrase.split(" ").length}"
        
        #checking if submission contains the review and that only NGRAM number of review tokens are compared
        if(rev_phrase.split(" ").length == NGRAM and submission.downcase.include?(rev_phrase.downcase))
          result = true
          break
        end
        #System.out.println("^^^ Plagiarism result:: "+result);
        rev_len+=1
      end #end of the while loop
      if(result == true)
        break
      end  
    end #end of for loop for submission
    if(result == true)
      break
    end
  end #end of for loop for reviews    
  return result
end
#-------------------------
=begin
Check for plagiarism after removing text within quotes for reviews
=end
def remove_text_within_quotes(review_text)
  puts "Inside removeTextWithinQuotes:: "
  reviews = Array.new
  review_text.each{ |row|
    puts "row #{row}"
    text = row 
    #text = text[1..text.length-2] #since the first and last characters are quotes
    #puts "text #{text}"
    #the read text is tagged with two sets of quotes!
    if(text.include?("\""))
      while(text.include?("\"")) do
        replace_text = text.scan(/"([^"]*)"/)
        # puts "replace_text #{replace_text[0]}.. #{replace_text[0].to_s.class} .. #{replace_text.length}"
        # puts text.index(replace_text[0].to_s)
        # puts "replace_text length .. #{replace_text[0].to_s.length}"
        #fetching the start index of the quoted text, in order to replace the complete segment
        start_index = text.index(replace_text[0].to_s) - 1 #-1 in order to start from the quote
        # puts "text[start_index..start_index + replace_text[0].to_s.length+1] .. #{text[start_index.. start_index + replace_text[0].to_s.length+1]}"
        #replacing the text segment within the quotes (including the quotes) with an empty string
        text.gsub!(text[start_index..start_index + replace_text[0].to_s.length+1], "")
        puts "text .. #{text}"
      end #end of the while loop
    end
    reviews << text #set the text after all quoted segments have been removed.
  } #end of the loop for "text" array
  puts "returning reviews length .. #{reviews.length}"
  return reviews #return only the first array element - a string!
end
#-------------------------    
end

    
