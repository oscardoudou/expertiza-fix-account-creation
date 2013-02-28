require 'automated_metareview/sentence'
require 'automated_metareview/cluster'
require 'automated_metareview/sentence_similarity'
require 'automated_metareview/cluster_generation'
require 'automated_metareview/topic_sentence_identification'
require 'automated_metareview/wordnet_based_similarity'

=begin
 Identifying the degree of coverage of a submission (text under review) by a review 
=end
class Coverage

def get_coverage(review_text, submission_text, review_graph, submission_graph, speller)

  #holds the sentences from the reivew and submission texts
  subm_sentences = Array.new
      
  #Step 1: Generating a graph-based representation of the submission
  #set the review/submission vertices and edges
  #since Reviews and Submissions "should" contain the same number of records
  subm_sentences = Array.new
  for i in (0..submission_text.length-1)     
    subm_sentences[i] = Sentence.new(i, submission_graph[i].vertices, submission_graph[i].edges,\
            submission_graph[i].vertices.length, submission_graph[i].edges.length)
    #getting the text for the corresponding graph sentence
    subm_sentences[i].sentence = submission_text[i]
  end
  
  #calculate similarities between every pair of sentence
  sent_sim = SentenceSimilarity.new
  subm_sentences_similarity = sent_sim.get_sentence_similarity(subm_sentences, speller)
      
  #Steps 2 and 3: Grouping sentences into clusters AND Identifying the clusters that need covering
  cluster_generation = ClusterGeneration.new
  clusters = cluster_generation.generate_clusters(subm_sentences, subm_sentences_similarity, sent_sim) 
  #passing the sent_sim instance since it contains sent_pairs info.
      
  #Step 4: Identifying topic representative sentences from each cluster
  topic_sentence = TopicSentenceIdentification.new
  topic_sentence.find_topic_sentences(clusters, subm_sentences_similarity)
  
  #Step 5: Grouping topic sentences together
  topic_sentences = ""
  for i in 0..clusters.length-1
    for j in 0..clusters[i].topic_sentences.length-1
      #selecting the submission sentence with the corresponding ID
      topic_sentences = topic_sentences+ " " + submission_text[clusters[i].topic_sentences[j].ID]
    end
  end
  #grouping review sentences together
  review_sentences = ""
  for i in (0..review_text.length-1)     
    review_sentences = review_sentences +" "+review_text[i]
  end
  
  # puts "topic sentence #{topic_sentences}"
  # puts "review_text #{review_sentences}"
  #Compare topic sentences with the review text   
  return calculate_coverage(topic_sentences, review_sentences) 
end #end of get_relevance

def calculate_coverage(topic_sentences, review_text)
  similarity_instance = WordnetBasedSimilarity.new

  #counting the number of tokens in topic_sentences
  topic_sentences_tokens = topic_sentences.split(" ")
  topic_sentences_tokens_cou = 0
  for  i in 0..topic_sentences_tokens.length-1
    # puts "topic_sentences_tokens[#{i}] .. #{topic_sentences_tokens[i]}"
    if(!topic_sentences_tokens[i].empty? and !similarity_instance.is_frequent_word(topic_sentences_tokens[i]))
        topic_sentences_tokens_cou+=1
    end
  end
  #counting the number of tokens in the review_text
  review_text_tokens = review_text.split(" ")
  review_text_tokens_cou = 0
  for  i in 0..review_text_tokens.length-1
    # puts "review_text_tokens[#{i}] .. #{review_text_tokens[i]}"
    if(!review_text_tokens[i].empty? and !similarity_instance.is_frequent_word(review_text_tokens[i]))
        review_text_tokens_cou+=1
    end
  end
  #determining the match between topic_sentences and the review_text
  match = 0
  for  i in 0..review_text_tokens.length-1
    if(!review_text_tokens[i].empty? and !similarity_instance.is_frequent_word(review_text_tokens[i])\
      and topic_sentences.include?(review_text_tokens[i]))
        match+=1
    end
  end
  puts "match #{match} topic_sentences_tokens_cou #{topic_sentences_tokens_cou} review_text_tokens_cou #{review_text_tokens_cou}"
  if(topic_sentences_tokens_cou + review_text_tokens_cou  != 0)
    result = match.to_f/(topic_sentences_tokens_cou + review_text_tokens_cou).to_f
  else
    result = 0
  end
    
  return result
end
end