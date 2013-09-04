require 'automated_metareview/constants'
class ClusterGeneration
=begin
  Forming the clusters in the dataset
   * @param subm_sentences is the set of sentences in the submission
   * @param sentence_similarity is the matrix containing the similarities between every pair of sentences
=end
def generate_clusters(subm_sentences, sentence_similarity)   
  #ranking sentence pairs based on their similarity
  ranked_array = rank_sentences(sentence_similarity)
  #Cluster creation -- looping
  final_clusters = cluster_creation(subm_sentences, ranked_array, sentence_similarity)
    
  #printing the clusters and calculating the avg. number of sentences per cluster
  num_sentences = 0
  count = 0
  for i in 0..final_clusters.length-1
    #copying only the required number of sentences into the final cluster
    if(final_clusters[i].sent_counter >= 0)
      #summing up number of sentences to calculate avg. number of sentences per cluster
      num_sentences += final_clusters[i].sent_counter
      count+=1
    end
  end
  @@sent_density_thresh = Math.round(numSentences/count);
  puts("Avg. number of sentences per clutser: #{@@sent_density_thresh}")
    
  #selecting the top 'n' clusters that need covering
  final_clusters = select_top_clusters(final_clusters)
  return final_clusters
end

=begin
   * @param
   * @return ids of ranked sentences
=end
def rank_sentences(sentence_similarity)
  order_sim_list = sentence_similarity.sim_list
  #ranked_array consists of the sentence IDs
  #number of sentence similarities = n(n-1)/2
  len = (sentence_similarity[0].length * (sentence_similarity[0].length-1))/2 
  ranked_array = Array.new(len){Array.new(2)}
  counter = 0 #counter for the ranked_array
  for i in 0..order_sim_list.length-1
    flag = 0 #to check if that similarity value was spotted in the matrix
    for j in 0..sentence_similarity.length - 1
      for k in 0..sentence_similarity.length - 1
        if(j < k)
          if(order_sim_list[i] == sentence_similarity[j][k])
            ranked_array[counter][0] = j #setting the sentence IDS
            ranked_array[counter][1] = k
            counter+=1
            flag = 1
            next
          end
        elsif(k < j)
          if(order_sim_list[i] == sentence_similarity[k][j])
            ranked_array[counter][0] = k #setting the sentence IDS
            ranked_array[counter][1] = j
            counter+=1
            flag = 1
            next
          end
        end
      end
      if(flag == 1)
        next
      end    
    end
  end
  return ranked_array 
end

=begin
   * @param subm_sentences - set of submission sentences
   * @param ranked_array - ranked set of sentences
   * @param sentence_similarity - matrix containing similarity between every pair of sentences
=end
  def cluster_creation(subm_sentences, ranked_array, sentence_similarity)
    cluster_set = Array.new(subm_sentences.length)
    #initialize every sentence to one cluster
    for i in 0..subm_sentences.length - 1
      cluster_set[i] = Cluster.new(i, 1, 0) #setting average cluster similarity to 0 since there are no edges initially
      cluster_set[i].sentences = Array.new(subm_sentences.length) #since a single cluster can contain atmost all sentences in the text
      cluster_set[i].sentences[0] = subm_sentences[i] #setting sentence
      
      #setting cluster ID for sentences - to check if sentences were a part of the same cluster
      subm_sentences[i].cluster_ID = cluster_set[i].ID
      puts("Cluster: #{i} SentCount: #{cluster_set[i].sent_counter}")
    end
    
    #creating clusters after checking cluster condition
    #iterating through every sentence in the ranked array
    for i in 0..ranked_array.length-1
      #fetching sentences
      s1 = subm_sentences[ranked_array[i][0]]
      s2 = subm_sentences[ranked_array[i][1]]
      puts("** Checking sentence IDS:  #{ranked_array[i][0]} - #{ranked_array[i][1]}")
      puts(" in clusters: #{s1.cluster_ID} - #{s2.cluster_ID}")
      s1_clust = cluster_set[s1.cluster_ID]
      s2_clust = cluster_set[s2.cluster_ID]
      
      #getting similarity between the two sentences
      if(s1.ID < s2.ID)
        sim = sentence_similarity[s1.ID][s2.ID]
      else
        sim = sentence_similarity[s2.ID][s1.ID]
      end
      
      if(sim < MINMATCH) #if the edge match is below a certain threshold, then no clusters may be formed between them
        next
      end
      
      if(s1.cluster_ID == s2.cluster_ID) #both sentences are in the same cluster
        next
      else #add one sentence to the other's cluster
        #check if s1 can be added to s2's cluster
        #deciding which cluster the other sentence should be added
        if(s1_clust.sent_counter != s2_clust.sent_counter) #when both clusters have different number of sentences
          #compare s1 with every sentence in the s2's cluster and get the avg. similarity
          #if s2_clust has more sentences
          if(s2_clust.sent_counter > 1 and checkingClusteringCondition(s1, s2_clust, s1_clust, sentence_similarity) == true) #if the condition was satisfied
            puts("# sents. in cluster: #{s2_clust.ID} - #{s2_clust.sent_counter}")
            puts("# sents. in cluster: #{s1_clust.ID} - #{s1_clust.sent_counter}")
            next #to the next sentence, since s1 has been added to s2_clust
          #check if s2 can be added to s1's cluster
          #if s1_clust has more sentences
          elsif(s1_clust.sent_counter > 1 and checkingClusteringCondition(s2, s1_clust, s2_clust, sentence_similarity) == true) #if the condition was satisfied
            puts("# sents. in cluster: #{s1_clust.ID} - #{s1_clust.sent_counter}")
            puts("# sents. in cluster: #{s2_clust.ID} - #{s2_clust.sent_counter}")
            next #to the next sentence, since s1 has been added to s2_clust
          end
        else #if both clusters have same number of sentences, either cluster could be the target
          #compare s1 with every sentence in the s2's cluster and get the avg. similarity
          if(checkingClusteringCondition(s1, s2_clust, s1_clust, sentence_similarity) == true) #if the condition was satisfied
            puts("# sents. in cluster: #{s2_clust.ID} - #{s2_clust.sent_counter}")
            puts("# sents. in cluster: #{s1_clust.ID} - #{s1_clust.sent_counter}")
            next #to the next sentence, since s1 has been added to s2_clust
          end
        end
      end
    end
    #recalculate the cluster average
    return cluster_set
  end #end of method cluster_creation

  def checkingClusteringCondition(s, targetClust, origClust, sentenceSimilarity)
    targetclust_sents = targetClust.sentences
    sum = 0.0
    count = 0
    for j in 0..targetClust.sent_counter-1
      #get similarity value between s1 and every sentence in s2Clust, except s1 itself!, 
      #therefore only < and > operations
      if(s.ID < targetclust_sents[j].ID) #since only the matrix' upper half has been calculated
        sum += sentenceSimilarity[s.ID][targetclust_sents[j].ID]
        count+=1
      elsif(s.ID > targetclust_sents[j].ID)
        sum += sentenceSimilarity[targetclust_sents[j].ID][s.ID]
        count+=1
      end
    end
    avgSim = 0.0
    if(count > 0)
      avgSim = sum/Float(count)
    end
    puts("Average similairty for sentence: #{s.ID} for cluster #{targetClust.ID} SIM: #{avgSim}")
    
    #checking cluster condition
    puts("Target cluster #{targetClust.ID}'s similarity: #{targetClust.avg_similarity}")
    puts("Original cluster #{origClust.ID}'s similarity: #{origClust.avg_similarity}")
    #then s1 can be added to the cluster, if it is within Y of the cluster's similarity as well as 
    #if the cluster it is being added to has a higher avg. sim. than the current cluster
    if((targetClust.avg_similarity - avgSim) <= SentenceSimilarity.simThreshold and 
        ((targetClust.avg_similarity == 0 && origClust.avg_similarity == 0) || 
            (targetClust.avg_similarity > origClust.avg_similarity)))
      #avgSim >= targetClust.avg - Similarity since the avgSim is not likely to exceed the cluster's similairty! 
      puts("Condition satisfied by the sentence for the targetcluster")
      s.clusterID = targetClust.ID
      
      #adding s1 to s2Clust's sentences
      targetClust.sentences[targetClust.sent_counter] = s
      targetClust.sent_counter++ #incrementing sentence counter
      #recalculating cluster average similarity
      targetClust.avg_similarity = recalculate_cluster_similarity(targetClust, sentenceSimilarity)
      
      #removing s1 from s1Clust's sentences
      for k in 0..origClust.sentences.length - 1 
        if(origClust.sentences[k]==s)
          next
        end
      end
      
      origClust.sentences[k] = nil #setting the location where s1 was earlier to null
      origClust.sent_counter-- #decrementing sentence counter
      #recalculating cluster average similarity
      origClust.avg_similarity = recalculate_cluster_similarity(origClust, sentenceSimilarity)
      return true
    end
    return false
  end
  
=begin
   * @param - c cluster whose average similarity is to be calculated
   * @param - the sentence similarity matrix
=end
  def recalculate_cluster_similarity(c, sent_sim)
    puts("****** Inside recalculate_cluster_similarity, #sentences in cluster: #{c.ID} is - #{c.sent_counter}")
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
          sum += sent_sim[clust_sents[i].ID][clust_sents[j].ID]
        else
          sum += sent_sim[clust_sents[j].ID][clust_sents[i].ID]
        end
        count+=1
      end
    end

    #calculating the cluster's average similarity value
    if(count > 0)
      avg = sum/Float(count)
    end
    puts("Cluster #{c.ID}'s recalculated average: #{avg}")
    return avg
  end
  
=begin
   * @param Cluster[] set of clusters to select the most important clusters based on 
   * 1. Number of sentences in the cluster and 
   * 2. Average similarity of the sentences in the cluster.
=end

  def select_top_clusters(subm_clusters)
    top_clusters = Array.new(subm_clusters.length)
    count = 0
    #code for selecting the top 'n' dense clusters
    for i in 0..subm_clusters.length-1
      if(subm_clusters[i].sent_counter >= @@sent_density_thresh)
        puts("Top cluster ID: #{subm_clusters[i].ID}")
        top_clusters[count] = subm_clusters[i]
        count+=1
      end
    end
    return top_clusters
  end
  
=begin
   * Calculating average similarity for every sentence in a cluster with every other sentence in the cluster,
   * and this across all clusters!
   * @param subm_clusters
   * @param sent_sim
=end
  def calculate_sentence_similarities_within_cluster(subm_clusters, sent_sim)
    #iterating through each of the clusters
    for i in 0..subm_clusters.length-1
      puts("Cluster: #{subm_clusters[i].ID} #sents: #{subm_clusters[i].sent_counter}")
      clust_sents = subm_clusters[i].sentences
      #iterating through all sentences in the cluster
      for j in 0..subm_clusters[i].sent_counter-1
        sum = 0.0
        count = 0
        #iterating through all sentences in the cluster
        for k in 0..subm_clusters[i].sent_counter-1
          puts("IDS: #{clust_sents[j].ID} - #{clust_sents[k].ID}")
          if(j != k)
            if(clust_sents[j].ID < clust_sents[k].ID)
              puts("sent_sim[#{clust_sents[j].ID}][#{clust_sents[k].ID}] #{sent_sim[clust_sents[j].ID][clust_sents[k].ID]}")
              sum += sent_sim[clust_sents[j].ID][clust_sents[k].ID]
              count+=1
            elsif(clust_sents[k].ID < clust_sents[j].ID)
              puts("sent_sim[#{clust_sents[k].ID}][#{clust_sents[j].ID}] #{sent_sim[clust_sents[k].ID][clust_sents[j].ID]}")
              sum += sent_sim[clust_sents[k].ID][clust_sents[j].ID]
              count+=1
            end
          end
        end #end of for condition for inner 'k'
        clust_sents[j].avg_similarity = sum/Float(count)
        pust("Sentence: #{clust_sents[j].ID} sim: #{clust_sents[j].avg_similarity}")
      end #end of for loop for outer sentences 'j'
    end #end of for loop for the clusters
  end
    
end
