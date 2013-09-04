require 'automated_metareview/sentence'
require 'automated_metareview/sentence_similarity'
require 'automated_metareview/cluster_generation'
require 'automated_metareview/topic_sentence_identification'
require 'automated_metareview/degree_of_relevance'

class ReviewCoverage

  def calculate_coverage(submissions, reviews, pos_tagger, core_NLP_tagger, speller)
    
    #Step 1: Converting submission's text into sentences
    subm_sents = Array.new
    g = GraphGenerator.new
    for i in (0..submissions.length - 1)
      g.generate_graph(submissions, pos_tagger, core_NLP_tagger, true, false)
      subm_sents << Sentence.new(i, g.vertices, g.edges, g.num_vertices, g.num_edges)
    end
    
    #calculate sentence similarity
    ssim = SentenceSimilarity.new
    subm_sentences_similarity = ssim.get_sentence_similarity(pos_tagger, subm_sents, speller)
    
    #Steps 2 and 3: Grouping sentences into clusters AND Identifying the clusters that need covering
    cg = ClusterGeneration.new
    clusters = cg.generate_clusters(subm_sents, subm_sentences_similarity)
    
    #Step 4: Identifying topic representative sentences from each cluster
    topic_sentence = TopicSentenceIdentification.new
    topic_sentence.find_topic_sentences(clusters, subm_sentences_similarity)
    
    #Step 5:  Measuring coverage of topic sentences by the review - review coverage calculation
    for i in 0..reviews.length-1 #for every class
      #generating the submission's graph
      g.generate_graph(reviews, pos_tagger, core_NLP_tagger, true, false)
      review_sentences << Sentence.new(i, g.vertices, g.edges, g.num_vertices, g.num_edges)
    end
    
    coverage = review_topic_sentence_overlaps(review_sentences, clusters, pos_tagger)
    puts("Coverage: #{coverage}")
    return coverage
  end  

=begin
   * Identifying coverage of the submission by the review
   * @param rev_sentences - sentences in the review
   * @param subm_clusters - clusters in the submission
   * @throws ClassNotFoundException 
=end
  def review_topic_sentence_overlaps(rev_sentences, subm_clusters, pos_tagger)
    puts("Inside identifyReviewCoverage, # rev. sentences: #{rev_sentences.length}")
    graph_match = DegreeOfRelevance.new
    
    #iterating though each of the clusters
    for i in 0..subm_clusters.length-1
      puts("Cluster #{subm_clusters[i].ID}")
      #fetching topic sentences
      topic_sent_clust = subm_clusters[i].topic_sentences
      avg_sim_for_clust = 0.0 #captures cluster's average, based on its topic sents' avg. similarity
      puts("# topic sentences in the cluster: #{topic_sent_clust.length}")
      
      #iterating through all the topic sentences in the cluster
      for j in 0..topic_sent_clust.length-1
        #iterating through each of the review sentences
        for k in 0..rev_sentences.length-1
          #calculating sum of all the topicSentence---reviewSentence coverage
          avg_sim_for_clust += (graph_match.compareVertices(pos_tagger, topic_sent_clust[j].vertices, rev_sentences[k].vertices, topic_sent_clust[j].num_vertices, rev_sentences[k].num_vertices) + 
              graph_match.compare_edges(pos_tagger, topic_sent_clust[j].edges, rev_sentences[k].edges, topic_sent_clust[j].num_edges, rev_sentences[k].num_edges))/Float(2)
        end
      end #end of for loop for cluster's topic sentences
      
      #getting the average similarity b/w the topic sentences and the review sentences
      subm_clusters[i].degree_covered_by_review = avg_sim_for_clust/Float(topic_sent_clust.length * rev_sentences.length)
      puts("^^^^ Avg. coverage : #{subm_clusters[i].degree_covered_by_review}")
    end #end of the for loop for the number of clusters
    
    return calculate_cluster_coverage(subm_clusters)
  end
  
=begin  
   * calculates the degree of coverage of each of the submission clusters
   * @param subm_clusters - the set of submission clusters
=end   
  def calculate_cluster_coverage(subm_clusters)
    puts("Inside calculateClusterCoverage for #clusters: #{subm_clusters.length}")
    coverage = 0.0
    for i in 0..subm_clusters.length-1
      puts("Cluster: #{subm_clusters[i].ID}'s coverage: #{subm_clusters[i].degree_covered_by_review}")
      coverage += subm_clusters[i].degree_covered_by_review;
    end
    puts("coverage: #{coverage} length #{subm_clusters.length}")
    coverage = coverage/Float(subm_clusters.length)
    puts("******* Degree of coverage of the review is: #{coverage}")
    return coverage
  end

end