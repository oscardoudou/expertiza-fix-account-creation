class TopicSentenceIdentification

  def find_topic_sentences(clusters, sentence_similarity)
    msort = MergeSorting.new

    #obtaining the average similarities between every pair of sentences, across all clusters
    #this is necessary for sorting sentences in the cluster, after which cluster cover is found in method 'coverage'
    cg = ClusterGeneration.new
    cg.calculate_sentence_similarities_within_cluster(clusters, sentence_similarity)
    
    #iterating through each of the clusters
    for i in 0..clusters.length-1
      puts("******** Looking at cluster: #{clusters[i].ID} similarity: #{clusters[i].avg_similarity}")
      #ranking sentences in a cluster based on their similarity value
      clust_sents = clusters[i].sentences
      #int numSentsInClust = clusters[i].sentCounter;
      #converting the array to ArrayList and back to Array for sorting purpose
      #sorting sentences based on their average similarity within the cluster
      ranked_sents = msort.sort(clust_sents, 1) #second flag to 'sorting' is 1 - to indicate 'sentence'
      
      #initialize topic sentences array for the cluster
      topic_sents = Array.new(clust_sents.length)
      count = 0
      
      #threshold is for checking if a sentence covers adjacent sentences with a considerably high similarity values
      cluster_thresh = clusters[i].avg_similarity
      #fetching only the first digit after the decimal point
      #find the floor of the value, since threshold forms lower bound of similarity and you don't want it to be too high!
      cluster_thresh = Float((cluster_thresh * 10).floor/10)
      puts("Cluster threshold: #{cluster_thresh}")
      
      #initialize first sentence as the topic sentence
      for j in 0..ranked_sents.length-1
        topic_sents[count] = ranked_sents[j] #selecting the ranked_sents one by one
        puts("topic_sents[#{count}] : #{topic_sents[count].ID}")
        count+=1
        #check coverage of the important sentences of the cluster by this sentence
        coverage = coverage(topic_sents, count, clust_sents, sentence_similarity, cluster_thresh)
        if(coverage == false)
          count-=1 #sentence that was added wasn't a topic sentence, so decrease the coverage
        end
      end #end of for loop for topic sentences identification
      #implies the current set of sentences in 'topic_sents' covers the sentences in the cluster
      puts("***** Number of topic sentences for cluster: #{clusters[i].topic_sentences.length}")
    end #end of for loop for clusters
  end

=begin
   * Checking if 's' covers all the sentences in 'sents' that are above a threshold
   * @param topic_sents - the set of sentences that we want to check if it covers the sentences in 'sents_to_cover'
=end
  def coverage(topic_sents, topic_sent_count, sents_to_cover, sentSim, threshold_topic_sentence)
    puts("Inside coverage, #topic sents.: #{topic_sent_count}")
    covered = false
    #iterating through the sentences that need to be covered
    for i in 0..sents_to_cover.length-1
      #checking that this sentence is not already covered
      if(sents_to_cover[i].flag_covered == false)
        puts("Sentence to cover: #{sents_to_cover[i].ID}")
        #covered = false;//setting covered for the sentence to false
        for j in 0..topic_sent_count-1
          if(sents_to_cover[i].ID == topic_sents[j].ID) #if the sentence to cover is the same as the topic sentence
            sents_to_cover[i].flag_covered = true
            covered = true #it is covered, else on breaking it returns false
            next
          end
          #threshold_topi_sentence varies with
          if(sents_to_cover[i].ID < topic_sents[j].ID and sentSim[sents_to_cover[i].ID][topic_sents[j].ID] >= threshold_topic_sentence) 
            puts("*** Sentence #{sents_to_cover[i].ID} Covered by #{topic_sents[j].ID}")
            #if a high sim. edge exists between the sentence to be covered and the current sentence, then it is covered
            sents_to_cover[i].flag_covered = true
            covered = true #the sentence in 'sents_to_cover' was covered by the 'sents'
            next #break out since sentence was covered
          elsif(topic_sents[j].ID < sents_to_cover[i].ID && sentSim[topic_sents[j].ID][sents_to_cover[i].ID] >= threshold_topic_sentence)
            puts("*** Sentence #{sents_to_cover[i].ID} Covered by #{topic_sents[j].ID}")
            #if a high sim. edge exists between the sentence to be covered and the current sentence, then it is covered
            sents_to_cover[i].flag_covered = true
            covered = true #the sentence in 'sents_to_cover' was covered by the 'sents'
            next #break out since sentence was covered
          end
        end #end of inner for loop for topic sentences
      end
    end #outer for loop for sentences to be covered
    
    #if the topic sentences did not cover any of the cluster's sentences
    if(covered == false)
      return false
    end
    return true #if all sentences in 'sents_to_cover' are covered
  end
end