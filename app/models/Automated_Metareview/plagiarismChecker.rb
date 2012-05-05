require 'Automated_Metareview/textCollection'
#require 'faster_csv'
class PlagiarismChecker

=begin
 reviewText and submText are array containing review and submission texts 
=end
def plagiarismCheck(reviewText, submText)
  reviewText = removeTextWithinQuotes(reviewText) #reviewText is an array
    
  n = 5 #5-gram matches
  result = false
  for l in 0..reviewText.length - 1 #iterating through the review's sentences
    review = reviewText[l]
    puts "review.class #{review.class}.. review - #{review}"
    for m in 0..submText.length - 1 #iterating though the submission's sentences
      submission = submText[m]  
      puts "submission.class #{submission.class}..submission - #{submission}"
      revLen = 0
      #System.out.println("Candidate: "+review);
      rev = review.split(" ") #review's tokens, taking 'n' at a time
      array = review.split(" ")   
      puts array.length
      
      while(revLen < array.length) do
        if(array[revLen] == " ") #skipping empty
          puts "skipping empty string: "
          revLen+=1
          next
        end
        
        #generating the sentence segment you'd like to compare
        revPhrase = array[revLen]
       
        add = 0 #add on to this when empty strings found  
        
        for j in revLen+1..(n+revLen+add-1) #concatenating 'n' tokens
          #puts "array[j] #{array[j]}, j #{j}"
          if(j < array.length)
            if(array[j] == "") #skipping empty
              puts("skipping empty string: ")
              add+=1
              next
            end
            revPhrase = revPhrase +" "+  array[j]
          end
        end
        #System.out.println("printing j: "+j);
        if(j == array.length)
          #if j has reached the end of the array, then reset revlen to the end of array to, or shorter strings will be compared
          revLen = array.length
        end
        
        #if(submission.contains("."))
          #submission = submission.substring(0, submission.indexOf("."));//ps.replaceAll(".", "") - DOESNT WORK
        if(submission.include?("\""))
          submission.gsub!("\"", "")
        end
        if(submission.include?(","))
          submission.gsub!(",", "")
        end
        if(submission.include?(";"))
          submission.gsub!(";", "")
        end
        if(submission.include?("!"))
          submission.gsub!("!", "")
        end
        #if(revPhrase.contains("."))
          #revPhrase = revPhrase.replaceAll(".", "");
        if(revPhrase.include?(","))
          revPhrase.gsub!(",", "")
        end
        if(revPhrase.include?(";"))
          revPhrase.gsub!(";", "")
        end
        if(revPhrase.include?("!"))
          revPhrase.gsub!("!", "")
        end
        puts "Review phrase: #{revPhrase}"
        #puts "Submission phrase: #{submission}"
        #checking if submission contains the review
        if(submission.downcase.include?(revPhrase.downcase))
          result = true
          break
        end
        #System.out.println("^^^ Plagiarism result:: "+result);
        revLen+=1
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
def removeTextWithinQuotes(reviewText)
  puts "Inside removeTextWithinQuotes:: "
  reviews = Array.new
  reviewText.each{ |row|
    puts "row #{row}"
    text = row 
    puts "text #{text.class}" 
    #text = text[1..text.length-2] #since the first and last characters are quotes
    #puts "text #{text}"
    #the read text is tagged with two sets of quotes!
    if(text.include?("\""))
      while(text.include?("\"")) do
        #puts("Length of text:: "+text.length())
        array = text.split(//)#split the string by characters
        firstIndex = -1
        lastIndex = -1
        for i in 0..array.length #since there could be more than one set of quotes!
          if(firstIndex == -1 and array[i] == '\"' and array[i+1] == '\"')
            firstIndex = i
            #System.out.println("firstIndex:: "+firstIndex);
          elsif(firstIndex != -1 and lastIndex == -1 and array[i] == '\"' and array[i+1] == '\"')
            lastIndex = i+1
            #System.out.println("lastIndex:: "+lastIndex)
          elsif(firstIndex != -1 and lastIndex != -1)
            substr = text[firstIndex..lastIndex+1]
            text.gsub!(substr, "") #replacing the substring with empty string.
            #System.out.println("Text:: "+text);
            break #out of the for loops
          end #end of the if condition
        end #end of the for loop
        reviews << text
      end #end of the while loop
    else
      reviews << text
    end  
  } #end of the loop for "text" array
  #puts "reviews[0] #{reviews[0]}"
  puts("Number of reviews (plagiarism) sentences:: #{reviews.length}")
  return reviews #return only the first array element - a string!
end
#-------------------------    
end

#-------------------------
# plag = PlagiarismChecker.new
# plagiarism = plag.plagiarismCheck("/Users/lakshmi/Documents/Thesis/Ruby-test/sample-review.csv", "/Users/lakshmi/Documents/Thesis/Ruby-test/sample-submission.csv")
# puts("plagiarism:: #{plagiarism}")

    
