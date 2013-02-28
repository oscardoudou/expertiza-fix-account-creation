class Cluster
  #attr_accessor auto creates the get and set methods for the following attributes
  attr_accessor :ID, :sentences, :sent_counter, :avg_similarity, :topic_sentences, :degree_covered_by_review
  def initialize(id, num_sent, avg_sim)
    @ID = id
    @sent_counter = num_sent
    @avg_similarity = avg_sim
    @degree_covered_by_review = 0.0
  end
end