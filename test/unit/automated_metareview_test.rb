require 'test_helper'

class AutomatedMetareviewTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "the truth" do
    assert true
  end
  
  # test "fetch review data array length" do
    # require 'automated_metareview/text_preprocessing'
    # tc = TextPreprocessing.new
    # map_id = 54808 #initialize some map_id from which the review comments can be extracted
    # instance = AutomatedMetareview.new
    # review = instance.fetch_review_data(map_id, tc)
    # assert_equal 4, review.length
  # end
#   
  # test "fetch review data array contents" do
    # require 'automated_metareview/text_preprocessing'
    # tc = TextPreprocessing.new
    # map_id = 54808 #initialize some map_id from which the review comments can be extracted
    # instance = AutomatedMetareview.new
    # review = instance.fetch_review_data(map_id, tc)
    # assert_equal "Good work!", review[0].to_s
    # assert_equal "Very Interesting!", review[1].to_s
    # assert_equal "Very original!", review[2].to_s
    # assert_equal "very good!", review[3].to_s
  # end
  
  test "fetch submission data array length" do
    require 'automated_metareview/text_preprocessing'
    tc = TextPreprocessing.new
    map_id = 54808 #initialize some map_id from which the review comments can be extracted
    instance = AutomatedMetareview.new
    submission = instance.fetch_submission_data(map_id, tc)
    assert_equal 5, submission.length
  end
  
  test "fetch submission data array contents" do
    require 'automated_metareview/text_preprocessing'
    tc = TextPreprocessing.new
    map_id = 54808 #initialize some map_id from which the review comments can be extracted
    instance = AutomatedMetareview.new
    submission = instance.fetch_submission_data(map_id, tc)
    assert_equal "This server called the SimpleWeb provides links and information on network management including software RFCs and tutorials.", submission[0].to_s
    assert_equal "Information is made available as a free service to the Internet and research community.", submission[2].to_s
    assert_equal "Note that the official URL of the SimpleWeb is:", submission[4].to_s
  end
end
