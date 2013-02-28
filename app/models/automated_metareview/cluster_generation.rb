require 'automated_metareview/merge_sort'
require 'automated_metareview/sentence_similarity'
require 'automated_metareview/cluster'

class ClusterGeneration
  attr_accessor :sent_threshold #based on maximum number of sentences among all clusters' sentCounter?
  
=begin Forming the clusters in the dataset
 subm_sentences is the set of sentences in the submission
  sentence_similarity is the matrix containing the similarities between every pair of sentences
=end
  def generate_clusters(subm_sentences, sentence_similarity, sent_sim) 
    #Some pre-processing before cluster generation
    #1. Computing average difference between sentences - sentence-sim-threshold - required for the clustering step
    sent_sim.compute_average_diff(subm_sentences, sentence_similarity)
    
    #2. Ordering similarities - required for the clustering step
    #System.out.println("*** simList.length: "+ SentenceSimilarity.sentPairs.length);//its global because we couldn't return two types from getSentenceSimilarity!
    sort = MergeSort.new
    sent_sim.sent_pairs = sort.sorting(sent_sim.sent_pairs, 3)
    #*** End of pre-processing ***/
    
    #Cluster creation -- looping
    final_clusters = cluster_creation(subm_sentences, sent_sim.sent_pairs, sentence_similarity)
    
    
    #*** Some post-processing after cluster generation ***/
    #1. Re-order sentences in a cluster so that the review sentences are higher in the order
    #2. Calculating the avg. number of sentences per cluster
    num_sentences = 0
    count = 0
    puts("*****Printing Clusters: #{final_clusters.length}")
    for i in 0..final_clusters.length-1 #for each cluster
      #summing up number of sentences to calculate avg. number of sentences per cluster
      puts("i #{i}")
      if(final_clusters[i].sent_counter > 0)
        num_sentences += final_clusters[i].sent_counter
        count += 1
        # #printing sentences in every cluster
        # #System.out.println("Printing cluster: "+i+" with #sentencees: "+finalClusters[i].sentCounter);
        # clust_sents = final_clusters[i].sentences
        # for(int j = 0; j < finalClusters[i].sentCounter; j++){
          # System.out.println("Sent: "+clustSents[j].ID);
        # end
      end
    end
    if(count > 0) #check else it would be a divide by 0
      @sent_threshold = (num_sentences/count).round
    else
      @sent_threshold = 0
    end
    puts("Avg. number of sentences per clutser: #{@sent_threshold}")
    
    #3. Pruning out clusters with fewer than average # of sentences i.e. SENTDENSITYTHRESH, and sim > 0
    final_clusters = select_top_clusters(final_clusters)
    
    #4. Sorting clusters based on their average similarities
    sorted_clusters = sort.sorting(final_clusters, 2)
    
    return sorted_clusters
  end
 
=begin
   * @param subm_sentences - set of submission sentences
   * @param ranked_array - ranked set of sentences with their IDs
   * @param sentence_similarity - matrix containing similarity between every pair of sentences
=end
  def cluster_creation(subm_sentences, ranked_array, sentence_similarity)
    min_match = 0.5 #no cluster formation between edges of such a low value
    cluster_set = Array.new
    #initialize every sentence to one cluster
    #System.out.println("Initializing clusters:");
    for i in 0..subm_sentences.length-1
      cluster_set[i] = Cluster.new(i, 1, 0) #setting average cluster similarity to 0 since there are no edges initially
      cluster_set[i].sentences = Array.new #since a single cluster can contain atmost all sentences in the text
      cluster_set[i].sentences[0] = subm_sentences[i] #setting sentence
      
      #setting cluster ID for sentences - to check if sentences were a part of the same cluster
      subm_sentences[i].cluster_ID = cluster_set[i].ID
      #System.out.println("Cluster:"+i+" SentCount: "+clusterSet[i].sentCounter);
    end
    
    #creating clusters after checking cluster condition
    #iterating through every sentence in the ranked array
    for i in 0..ranked_array.length-1
      #fetching sentences
      s1 = subm_sentences[ranked_array[i].sent1_ID]
      s2 = subm_sentences[ranked_array[i].sent2_ID]
      #System.out.print("** Checking sentence IDS: "+s1.ID +" - "+s2.ID);
      #System.out.println(" in clusters: "+s1.clusterID +" - "+s2.clusterID);
      s1_clust = cluster_set[s1.cluster_ID]
      s2_clust = cluster_set[s2.cluster_ID]
      
      #getting similarity between the two sentences
      if(s1.ID < s2.ID)
        sim = sentence_similarity[s1.ID][s2.ID]
      else
        sim = sentence_similarity[s2.ID][s1.ID]
      end
      #if the edge match is below a certain threshold, then no clusters may be formed between them
      if(sim < min_match)
        next #continue
      end
      
      if(s1.cluster_ID == s2.cluster_ID) #both sentences are in the same cluster
        next
      else #add one sentence to the other's cluster
        #System.out.println("***** Checking Cluster Condition");
        #check if s1 can be added to s2's cluster
        #Deciding which cluster the other sentence should be added - BASED ON CLUSTER'S AVERAGE SIMILARITY
        if(s1_clust.avg_similarity != s2_clust.avg_similarity) #when both clusters have different number of sentences
          #if target cluster (s2clust) has a higher similarity than the origin cluster
          if(s2Clust.avgSimilarity > s1Clust.avgSimilarity and
            checking_clustering_condition(s1, s2_clust, s1_clust, sentence_similarity) == true) #if the condition was satisfied
            #System.out.println("# sents. in cluster: "+s2Clust.ID+" - "+s2Clust.sentCounter);
            #System.out.println("# sents. in cluster: "+s1Clust.ID+" - "+s1Clust.sentCounter);
            next #to the next sentence, since s1 has been added to s2Clust
          #check if s2 can be added to s1's cluster
          elsif(s1_clust.avg_similarity > s2_clust.avg_similarity and
            checking_clustering_condition(s2, s1_clust, s2_clust, sentence_similarity) == true) #if the condition was satisfied
            #System.out.println("# sents. in cluster: "+s1Clust.ID+" - "+s1Clust.sentCounter);
            #System.out.println("# sents. in cluster: "+s2Clust.ID+" - "+s2Clust.sentCounter);
            next #to the next sentence, since s1 has been added to s2Clust
          end
        else #if both clusters have equal similarity values - check sentence counter
          if(s2_clust.sent_counter > s1_clust.sent_counter and 
              checking_clustering_condition(s1, s2_clust, s1_clust, sentence_similarity) == true) #s2's cluster has more sentences
              # System.out.println("# sents. in cluster: "+s2Clust.ID+" - "+s2Clust.sentCounter);
              # System.out.println("# sents. in cluster: "+s1Clust.ID+" - "+s1Clust.sentCounter);
              next #to the next sentence, since s1 has been added to s2Clust
          elsif(s1_clust.sent_counter > s2_clust.sent_counter and 
              checking_clustering_condition(s2, s1_clust, s2_clust, sentence_similarity) == true) #if s1's cluster has more sentences
              # System.out.println("# sents. in cluster: "+s1Clust.ID+" - "+s1Clust.sentCounter);
              # System.out.println("# sents. in cluster: "+s2Clust.ID+" - "+s2Clust.sentCounter);
              next #to the next sentence, since s1 has been added to s2Clust
          #if the similarities are equal and sentence counters are also equal!
          elsif(checking_clustering_condition(s1, s2_clust, s1_clust, sentence_similarity) == true) #if the condition was satisfied
            # System.out.println("# sents. in cluster: "+s2Clust.ID+" - "+s2Clust.sentCounter);
            # System.out.println("# sents. in cluster: "+s1Clust.ID+" - "+s1Clust.sentCounter);
            next #to the next sentence, since s1 has been added to s2Clust
          end
        end
      end
    end #end of the for loop for the ranked array of sentences
    
    #recalculate the cluster average
    return cluster_set
  end
  
  def checking_clustering_condition(s, target_clust, orig_clust, sentence_similarity)
    target_clust_sents = target_clust.sentences
    sum = 0
    count = 0
    #comparing s with every sentence in the target cluster
    for j in 0..target_clust.sent_counter-1
      #get similarity value between s1 and every sentence in s2Clust, except s1 itself!, 
      #therefore only < and > operations
      if(target_clust_sents[j] == null)
        next
      end
      
      #System.out.println("*** targetClustSents[j].ID: "+targetClustSents[j].ID);
      if(s.ID < target_clust_sents[j].ID) #since only the matrix' upper half has been calculated
        sum += sentence_similarity[s.ID][target_clust_sents[j].ID]
        count+=1
      elsif(s.ID > target_clust_sents[j].ID)
        sum += sentence_similarity[target_clust_sents[j].ID][s.ID]
        count+=1
      end
    end
    
    avg_sim = 0.0
    if(count > 0)
      avgSim = sum/count
    end
    
    #checking cluster condition
    #System.out.println("Target cluster "+targetClust.ID+"'s similarity: "+targetClust.avgSimilarity);
    #System.out.println("Original cluster "+origClust.ID+"'s similarity: "+origClust.avgSimilarity);
    #then s1 can be added to the cluster, if it is within Y of the cluster's similarity as well as 
    #if the cluster it is being added to has a higher avg. sim. than the current cluster
    if((target_clust.avg_similarity - avg_sim) <= SentenceSimilarity.sim_threshold) 
    #avgSim >= targetClust.avg - Similarity since the avgSim is not likely to exceed the cluster's similairty! 
    #System.out.println("Condition satisfied by the sentence for the targetcluster");
      s.cluster_ID = target_clust.ID
      #adding s1 to s2Clust's sentences
      target_clust.sentences[target_clust.sent_counter] = s
      target_clust.sent_counter+=1 #incrementing sentence counter
      #recalculating cluster average similarity
      target_clust.avg_similarity = recalculate_cluster_similarity(target_clust, sentence_similarity)
      
      #removing s1 from s1Clust's sentences
      #iterate till you find 's' in the cluster
      for k in 0..orig_clust.sentences.length-1
        if(orig_clust.sentences[k]!=s)
          next
        end
      end
      #now removing 's' from the cluster
      if(orig_clust.sentences[k] == s)
        #System.out.println("%%% Setting null for cluster: "+origClust.ID+"'s sentence: "+origClust.sentences[k].ID);
        orig_clust.sentences[k] = nil #setting the location where s1 was earlier to null

        #resetting the array to move elements after the "null" value,  one step ahead.
        #adding non-null elements to a temporary array
        temp = Array.new
        cou = 0
        for i in 0..orig_clust.sent_counter.length-1
          if(orig_clust.sentences[i] != nil)
            temp[cou] = orig_clust.sentences[i]
            cou+=1
          end
        end
        orig_clust.sentences = temp
        #decrementing sentence counter
        orig_clust.sent_counter-=1 #this is equal to 'cou'
        #recalculating cluster average similarity
        orig_clust.avg_similarity = recalculate_cluster_similarity(orig_clust, sentence_similarity)
     end #end of if condition
     return true
    end #end of for loop for k
    return false
  end
  
=begin
  c cluster whose average similarity is to be calculated
  the sentence similarity matrix
=end
  def recalculate_cluster_similarity(c, sent_sim)
    puts("****** Inside recalculateClusterSimilarity, #sentences in cluster: #{c.ID} is - #{c.sentCounter}")
    clust_sents = c.sentences
    num_sents_clust = c.sent_counter
    avg = 0.0
    
    if(num_sents_clust == 0)
      return 0.0 #if there are no sentences in the cluster sem. sim = 0
    end
    
    sum = 0
    count = 0 #since the cluster has an initial similarity value, with which you are taking an average
    for i in 0..num_sents_clust-1
      for j in i+1..num_sents_clust-1
        puts("Comparing sents: #{clust_sents[i].ID} && #{clust_sents[j].ID}")
        if(clust_sents[i].ID < clust_sents[j].ID)
          sum += sent_Sim[clust_sents[i].ID][clust_sents[j].ID]
        else
          sum += sent_sim[clust_sents[j].ID][clust_sents[i].ID]
        end
        count+=1
      end
    end

    #calculating the cluster's average similarity value
    if(count > 0)
      avg = sum/count
    end
    puts("Cluster #{c.ID}'s recalculated average: #{avg}")
    return avg
  end
  
=begin
   * @param Cluster[] set of clusters to select the most important clusters based on 
   * 1. Number of sentences in the cluster and 
   * 2. Average similarity of the sentences in the cluster.
   * The output of this method is a list of clusters, which satisfy the density and similarity conditions
   * These clusters are not ordered based on their density/ importance. 
=end
  def select_top_clusters(subm_clusters)
    top_clusters = Array.new
    count = 0
    #code for selecting the top 'n' dense clusters
    puts("********* Selected Clusters: ")
    for i in 0..subm_clusters.length-1
      #making sure the selected clusters have a sufficient number of sentences and also have a similarity value > 0
      if(subm_clusters[i].sent_counter >= @sent_threshold and subm_clusters[i].avg_similarity > 0)
        puts("Top cluster ID: #{subm_clusters[i].ID}")
        top_clusters[count] = subm_clusters[i]
        count+=1
      end
    end
    puts("top_clusters.length: #{top_clusters.length}")
    if(top_clusters.length == 0)#if no cluster is selected, then select all clusters
      top_clusters = subm_clusters
    end
    puts("top_clusters.length after: #{top_clusters.length}")
    return top_clusters
  end
end