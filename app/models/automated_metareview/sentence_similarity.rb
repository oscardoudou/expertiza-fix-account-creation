class SentenceSimilarity
attr_accessor :sim_list, :sim_threshold 
def get_sentence_similarity(pos_tagger, subm_sentences, speller)
  sim_list = Array.new 
  
  #calculating similarities between sentences
  sentence_match = Array.new(subm_sentences.length){Array.new}
  graph_match = DegreeOfRelevance.new
  for i in 0..subm_sentences.length - 1
    for j in 0..subm_sentences.length - 1
      if(i < j)
        puts("vertex - subm_sentences[i] = #{subm_sentences[i].nil?} and subm_sentences[j] = #{subm_sentences[j].nil?}")
        vertex_match = graph_match.compare_vertices(pos_tagger, subm_sentences[i].vertices, subm_sentences[j].vertices, subm_sentences[i].num_verts, subm_sentences[j].num_verts, speller)
        puts("edge - subm_sentences[i] = #{subm_sentences[i].nil?} and subm_sentences[j] = #{subm_sentences[j].nil?}")
        edge_match = graph_match.compare_edges_non_syntax_diff(subm_sentences[i].edges, subm_sentences[j].edges, subm_sentences[i].num_edges, subm_sentences[j].num_edges)
        sentence_match[i][j] = (vertex_match + edge_match)/2
        sim_list << sentence_match[i][j]
      end
    end
  end
  
  #calculating average difference between similarity values
  difference = 0.0 #maintains cumulative difference between values
  count = 0
  for i in 0..subm_sentences.length - 1
    for j in 0..subm_sentences.length - 1
      #since the similarity is symmetric only values of the top triangle in the matrix is calculated
      if(i < j) 
        if(i != j+1 and j+1 < subm_sentences.length) #the second condition is to avoid getting difference with sentence comparison with itself (leading diagonal)
            difference += (sentence_match[subm_sentences[i].ID][subm_sentences[j].ID] - 
              sentence_match[subm_sentences[i].ID][subm_sentences[j+1].ID]).abs
        end
        if(i == j+1 and j+2 < subm_sentences.length) #ensuring j+2 is less than the number of sentences
            difference += (sentence_match[subm_sentences[i].ID][submSentences[j].ID] - 
            sentence_match[subm_sentences[i].ID][subm_sentences[j+2].ID]).abs
        end
        count+=1
      end
      if(j < i)
        if((j+1) != i and j+1 < subm_sentences.length)
            difference += (sentence_match[subm_sentences[j].ID][subm_sentences[i].ID] - sentence_match[subm_sentences[j+1].ID][subm_sentences[i].ID]).abs
        end
        if ((j+1) == i && j+2 < submSentences.length)
            difference += (sentence_match[subm_sentences[j].ID][subm_sentences[i].ID] - sentence_match[subm_sentences[j+2].ID][subm_sentences[i].ID]).abs
        end
        count+=1
      end
    end
  end
  sim_threshold = difference/count
  sim_threshold = (sim_threshold * 10).round/10.0 #rounding to include only 1 digit after the decimal
  #order simlist
  sim_list = sim_list.sort
  
  return sentence_match
end  

end