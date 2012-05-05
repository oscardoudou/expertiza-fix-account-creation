require 'Automated_Metareview/wordnetBasedSimilarity'

class TextQuantity
  def numberOfUniqueTokens(textArray)
    preString = "" #preString helps keep track of the text that has been checked for unique tokens and text that has not
    count = 0 #counts the number of unique tokens
    instance = WordnetBasedSimilarity.new
    textArray.each{
      |text|
      if(text.include?("\""))
        text.gsub!("\"", "")
      end
      if(text.include?(","))
        text.gsub!(",", "")
      end
      if(text.include?(";"))
        text.gsub!(";", "")
      end
      if(text.include?("!"))
        text.gsub!("!", "")
      end
      #puts "text #{text}"
      allTokens = text.split(" ")
      #puts "allTokens #{allTokens}"
      allTokens.each{ 
        |token|
        if(!instance.isFrequentWord(token.downcase)) #do not count this word if it is a frequent word
          if(!preString.downcase.include?(token.downcase)) #if the token was not already seen earlier i.e. not a part of the preString
            puts "token .. #{token}"
            count+=1
          end  
        end  
        preString = preString +" " + token.downcase #adding token to the preString
        #puts "preString #{preString}"
      }
    }
    puts "Number of unique tokens #{count}"
    return count
  end
end