require 'test_helper'
require 'Automated_Metareview/text_quantity'
require 'Automated_Metareview/text_collection'
    
class ToneTest < ActiveSupport::TestCase
  
  # test "number of unique tokens without duplicate words" do
    # instance = TextQuantity.new
    # review_text = ["Parallel lines never meet."]
    # tc = TextCollection.new
    # review_text = tc.get_review(0, review_text)
    # num_tokens = instance.number_of_unique_tokens(review_text)
    # assert_equal(4, num_tokens)
  # end
#   
  # test "number of unique tokens with frequent words" do
    # instance = TextQuantity.new
    # review_text = ["I am surprised to hear the news."]
    # tc = TextCollection.new
    # review_text = tc.get_review(0, review_text)
    # num_tokens = instance.number_of_unique_tokens(review_text)
    # assert_equal(3, num_tokens)
  # end
  
  test "number of unique tokens with repeated words" do
    instance = TextQuantity.new
    review_text = ["The report is good, but more changes can be made to the report."]
    tc = TextCollection.new
    review_text = tc.get_review(0, review_text)
    num_tokens = instance.number_of_unique_tokens(review_text)
    assert_equal(6, num_tokens) #tokens:report, good, but, more, changes, made (others are stop words)
  end
end
