require 'Automated_Metareview/wordnet_based_similarity'
require 'Automated_Metareview/graph_generator'

class TextQuantity
  def number_of_unique_tokens(text_array)
    pre_string = "" #preString helps keep track of the text that has been checked for unique tokens and text that has not
    count = 0 #counts the number of unique tokens
    instance = WordnetBasedSimilarity.new
    text_array.each{
      |text|
      graph_inst = GraphGenerator.new
      text = graph_inst.contains_punct(text)
      #puts "text #{text}"
      all_tokens = text.split(" ")
      #puts "allTokens #{allTokens}"
      all_tokens.each{ 
        |token|
        if(!instance.is_frequent_word(token.downcase)) #do not count this word if it is a frequent word
          if(!pre_string.downcase.include?(token.downcase)) #if the token was not already seen earlier i.e. not a part of the preString
            puts "token .. #{token}"
            count+=1
          end  
        end  
        pre_string = pre_string +" " + token.downcase #adding token to the preString
        #puts "preString #{preString}"
      }
    }
    puts "Number of unique tokens #{count}"
    return count
  end
end