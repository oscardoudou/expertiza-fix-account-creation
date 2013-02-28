require 'automated_metareview/graph_match'
require 'automated_metareview/merge_sort'
require 'automated_metareview/sentence_pair'

=begin
 Identifying the degree of coverage of a submission (text under review) by a review 
=end
class SentenceSimilarity
attr_accessor :sent_pairs, :sim_threshold
def get_sentence_similarity(subm_sentences, speller)
    puts("*********** Inside getSentenceSimilarity: #{subm_sentences.length}")
    @sent_pairs = Array.new
    sort = MergeSort.new
    #initializing the matrix that holds the sentence similarities
    sentence_match = Array.new{Array.new}
    #i, j and their correspoding subm_sentences' IDS are the same and they can be used interchangeably
    #comparing sentence vertices and edges to determine cumulative similarity
    graph_match = GraphMatch.new
    sim_count = 0
    for i in (0..subm_sentences.length-1)
      sentence_match[subm_sentences[i].ID] = Array.new
      for j in (0..subm_sentences.length-1)
        #since the similarity is symmetric only values of the top triangle in the matrix is calculated
        if(subm_sentences[i].ID < subm_sentences[j].ID)
          sentence_match[subm_sentences[i].ID][subm_sentences[j].ID] = \
              (graph_match.compare_vertices(subm_sentences[i].vertices, subm_sentences[j].vertices,\
              subm_sentences[i].num_vertices, subm_sentences[j].num_vertices, speller) +\
              graph_match.compare_edges_non_syntax_diff(subm_sentences[i].edges, subm_sentences[j].edges,\
               subm_sentences[i].num_edges, subm_sentences[j].num_edges))/2
          @sent_pairs[sim_count] = SentencePair.new(subm_sentences[i].ID, subm_sentences[j].ID,\
              sentence_match[subm_sentences[i].ID][subm_sentences[j].ID])
          sim_count += 1
        end
      end
    end
    
    return sentence_match
  end

  def compute_average_diff(subm_sentences, sentence_match)
    #calculating average difference between similarity values
    difference = 0.0
    count = 0
    for i in 0..subm_sentences.length-1
      for j in 0..subm_sentences.length-1
        #since the similarity is symmetric only values of the top triangle in the matrix is calculated
        if(i < j)
          if(i != j+1 and j+1 < subm_sentences.length) #the second condition is to avoid getting difference with sentence comparison with itself (leading diagonal)
            difference += (sentence_match[subm_sentences[i].ID][subm_sentences[j].ID] -\
              sentence_match[subm_sentences[i].ID][subm_sentences[j+1].ID]).abs
            count += 1 #incrementing count for #differences - for average
          elsif(i == j+1 and j+2 < subm_sentences.length) #ensuring j+2 is less than the number of sentences
            #after incrementing (j+2) will still be greater than i
            difference += (sentence_match[subm_sentences[i].ID][subm_sentences[j].ID] -\
              sentence_match[subm_sentences[i].ID][subm_sentences[j+2].ID]).abs
            count += 1
          end
        elsif(j < i)
          if((j+1) != i)
            difference += (sentence_match[subm_sentences[j].ID][subm_sentences[i].ID] -\
              sentence_match[subm_sentences[j+1].ID][subm_sentences[i].ID]).abs
            count += 1
          elsif((j+1) == i and j+2 < subm_sentences.length)
            if(j+2 < i)
              difference += (sentence_match[subm_sentences[j].ID][subm_sentences[i].ID] -\
                sentence_match[subm_sentences[j+2].ID][subm_sentences[i].ID]).abs
              count += 1
            elsif(j+2 > i)
              difference += (sentence_match[subm_sentences[j].ID][subm_sentences[i].ID] -\
                sentence_match[subm_sentences[i].ID][subm_sentences[j+2].ID]).abs
              count += 1
            end
          end
        end
      end
    end
    
    #calculating average difference between different sentences
    if(count > 0)
      @sim_threshold = difference/count
    else
      @sim_threshold = 0
    end
    
    #since we want to extract the first digit after the period
    @sim_threshold = (@sim_threshold * 10).round/10 #we 'round' it to the next highest, since this threshold forms upper bound!
    puts("*** Difference: #{difference} count: #{count}*** simThreshold: #{@simThreshold}")
  end
end