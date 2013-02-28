require 'automated_metareview/merge_sort'

class TopicSentenceIdentification
  def find_topic_sentences(clusters, sentence_similarity)
    puts("*** Inside findTopicSentences for: #{clusters.length} clusters")
    sort = MergeSort.new
    #iterating through each of the clusters
    for i in 0..clusters.length-1
      puts("******** Looking at cluster: #{clusters[i].ID} similarity: #{clusters[i].avg_similarity}")
      
      # Some pre-processing before topic sentences identification ***/
      #1.Determining similarity threshold for each cluster 
      #Threshold is for checking if a sentence covers adjacent sentences with a considerably high similarity values
      cluster_thresh = clusters[i].avg_similarity #recalculated average after every cluster generation step
      #fetching only the first digit after the decimal point
      #find the floor of the value, since threshold forms lower bound of similarity and you don't want it to be too high!
      cluster_thresh = (cluster_thresh * 10/10).floor
      puts("Cluster's similarity threshold: #{cluster_thresh}")
      
      #2. Obtaining the average similarity value for each sentence in the cluster 
      #this is necessary for sorting sentences in the cluster, after which cluster cover is found in method 'coverage'
      #nowhere else is the sentence's avgSimilarity set in the code, this is the first time
      clust_sents = clusters[i].sentences
      calculate_sentence_sim_and_connectivity(clust_sents, sentence_similarity, cluster_thresh)
      
      #3. Ranking sentences in a cluster based on their similarity value
      #converting the array to ArrayList and back to Array for sorting purpose
      #sorting sentences based on their COVERAGE (number of sentence covered) within the cluster
      ranked_sents = sort.sorting(clust_sents, 1) #second flag to 'sorting' is 1 - to indicate 'sentence'
      #*** End of pre-processing ***
      
      #initialize topic sentences array for the cluster
      topic_sents = Array.new
      count = 0
      #initialize first sentence as the topic sentence
      for j in 0..ranked_sents.length-1
        topic_sents[count] = ranked_sents[j] #selecting the rankedSents one by one
        count+=1
        #check coverage of the important sentences of the cluster by this sentence
        coverage = coverage(topic_sents, count, clust_sents, sentence_similarity, cluster_thresh)
        if(coverage == false) #skipping review sentences as topic sentences
          count-=1 #sentence that was added wasn't a topic sentence, so decrease the coverage
        else
          puts("topicSents[#{(count-1)}] : #{topic_sents[count-1].ID}")
        end
      end #end of for loop for topic sentences identification
      #copying the topic sentences array with the correct number of sentences
      clusters[i].topic_sentences = topic_sents
      puts("***** Number of topic sentences for cluster: #{clusters[i].ID} is - #{clusters[i].topic_sentences.length}")
    end #end of for loop for clusters
  end

=begin  
  Checking if 's' covers all the sentences in 'sents' that are above a threshold
   * @param topicSents - the set of sentences that we want to check if it covers the sentences in 'sentsToCover'
=end
  def coverage(topic_sents, topic_sent_count, sents_to_cover, sent_sim, threshold_topic_sentence)
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
            break
          end
          if(sents_to_cover[i].ID < topic_sents[j].ID and sent_sim[sents_to_cover[i].ID][topic_sents[j].ID] >= threshold_topic_sentence) #threshold_topi_sentence varies with
            puts("*** Sentence #{sents_to_cover[i].ID} Covered by #{topic_sents[j].ID}")
            #if a high sim. edge exists between the sentence to be covered and the current sentence, then it is covered
            sents_to_cover[i].flag_covered = true
            covered = true #the sentence in 'sentsToCover' was covered by the 'sents'
            break #break out since sentence was covered
          elsif(topic_sents[j].ID < sents_to_cover[i].ID and sent_sim[topic_sents[j].ID][sents_to_cover[i].ID] >= threshold_topic_sentence)
            # System.out.println("*** Sentence"+ sentsToCover[i].ID+" Covered by "+topicSents[j].ID);
            #if a high sim. edge exists between the sentence to be covered and the current sentence, then it is covered
            sents_to_cover[i].flag_covered = true
            covered = true #the sentence in 'sentsToCover' was covered by the 'sents'
            break #break out since sentence was covered
          end
        end #end of inner for loop for topic sentences
      end
    end #outer for loop for sentences to be covered
    
    #if the topic sentences did not cover any of the cluster's sentences
    if(covered == false)
      return false
    end
    return true #if all sentences in 'sentsToCover' are covered
  end
  
=begin
   * Calculating average similarity for every sentence in a cluster with every other sentence.
   * Also calculating the number of sentences covered by a given sentence.
   * @param submClusters
   * @param sentSim
=end
  def calculate_sentence_sim_and_connectivity(clust_sents, sent_sim, sim_thresh)
    puts("**** Inside calculateSentenceSimilaritiesWithinCluster")   
    for j in 0..clust_sents.length-1
      sum = 0
      count = 0
      #iterating through all sentences in the cluster
      for k in 0..clust_sents.length-1
        puts("IDS: #{clust_sents[j].ID} - #{clust_sents[k].ID}")
        if(j != k)
          if(clust_sents[j].ID < clust_sents[k].ID)
            puts("sentSim[ #{clust_sents[j].ID}][#{clust_sents[k].ID}] #{sent_sim[clust_sents[j].ID][clust_sents[k].ID]}")
            sum += sent_sim[clust_sents[j].ID][clust_sents[k].ID]
            count+=1
            #incrementing sent counter if the sentence 'j' has a high degree of sim. with 'k'
            if(sent_sim[clust_sents[j].ID][clust_sents[k].ID] >= sim_thresh)
              clust_sents[j].sent_cover_num+=1
            end
          elsif(clust_sents[k].ID < clust_sents[j].ID)
            puts("sentSim[#{clust_sents[k].ID}][#{clust_sents[j].ID}] #{sent_sim[clust_sents[k].ID][clust_sents[j].ID]}")
            sum += sent_sim[clust_sents[k].ID][clust_sents[j].ID]
            count+=1
            #incrementing sent counter if the sentence 'j' has a high degree of sim. with 'k'
            if(sent_sim[clust_sents[k].ID][clust_sents[j].ID] >= sim_thresh)
              clust_sents[j].sent_cover_num+=1
            end
          end
        end
      end #end of for condition for inner 'k'
      if(count > 0)
        clust_sents[j].avg_similarity = sum/count
      else
        clust_sents[j].avg_similarity = 0
      end
      puts("Sentence: #{clust_sents[j].ID} sim: #{clust_sents[j].avg_similarity}")
    end #end of for loop for outer sentences 'j'
  end
end