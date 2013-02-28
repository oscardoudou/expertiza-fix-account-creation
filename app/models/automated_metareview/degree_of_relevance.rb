require 'automated_metareview/wordnet_based_similarity'
require 'automated_metareview/graph_generator'
require 'automated_metareview/graph_match'

class DegreeOfRelevance
#creating accessors for the instance variables
attr_accessor :vertex_match
=begin
  Identifies relevance between a review and a submission
=end  
def get_relevance(reviews, submissions, review_graph, submission_graph, speller) #double dimensional arrays that contain the submissions and the reviews respectively
  review_vertices = nil
  review_edges = nil
  subm_vertices = nil
  subm_edges = nil
  num_rev_vert = 0
  num_rev_edg = 0 
  num_sub_vert = 0 
  numSubEdg = 0
  vert_match = 0.0
  edge_without_syn = 0.0
  edge_with_syn = 0.0
  edge_diff_type = 0.0
  double_edge = 0.0
  double_edge_with_syn = 0.0
  
    #grouping vertices and edges from the different sentences in the review into one complete forest
    review_vertices = Array.new
    review_edges = Array.new
    for i in 0..review_graph.length - 1
      #grouping all vertices together      
      for j in 0..review_graph[i].vertices.length-1
        review_vertices <<  review_graph[i].vertices[j]
      end
      #grouping all edges together      
      for j in 0..review_graph[i].edges.length - 1
        review_edges <<  review_graph[i].edges[j]
      end
    end
    num_rev_vert = review_vertices.length
    num_rev_edg = review_edges.length
    
    #grouping vertices and edges from the different sentences in the submission into one complete forest
    subm_vertices = Array.new
    subm_edges = Array.new
    for i in 0..submission_graph.length - 1
      #grouping all vertices together      
      for j in 0..submission_graph[i].vertices.length - 1
        subm_vertices <<  submission_graph[i].vertices[j]
      end
      #grouping all edges together      
      for j in 0..submission_graph[i].edges.length - 1
        subm_edges <<  submission_graph[i].edges[j]
      end
    end
    num_sub_vert = subm_vertices.length
    num_sub_edg = subm_edges.length
    
    #Comparing review and submission graphs by comparing vertices and edges 
    graph_match = GraphMatch.new
    vert_match = graph_match.compare_vertices(review_vertices, subm_vertices, num_rev_vert, num_sub_vert, speller)
    if(num_rev_edg > 0 and num_sub_edg > 0)
      edge_without_syn = graph_match.compare_edges_non_syntax_diff(review_edges, subm_edges, num_rev_edg, num_sub_edg)
      edge_with_syn = graph_match.compare_edges_syntax_diff(review_edges, subm_edges, num_rev_edg, num_sub_edg)
      edge_diff_type = graph_match.compare_edges_diff_types(review_edges, subm_edges, num_rev_edg, num_sub_edg)
      edge_match = (edge_without_syn.to_f + edge_with_syn.to_f )/2.to_f #+ edge_diff_type.to_f
      double_edge = graph_match.compare_SVO_edges(review_edges, subm_edges, num_rev_edg, num_sub_edg)
      double_edge_with_syn = graph_match.compare_SVO_diff_syntax(review_edges, subm_edges, num_rev_edg, num_sub_edg)
      double_edge_match = (double_edge.to_f + double_edge_with_syn.to_f)/2.to_f
    else
      edge_match = 0
      double_edge_match = 0
    end
      
    #differently weighted cases
    #tweak this!!
    alpha = 0.55
    beta = 0.35
    gamma = 0.1 #alpha > beta > gamma
    relevance = (alpha.to_f * vert_match.to_f) + (beta * edge_match.to_f) + (gamma * double_edge_match.to_f) #case1's value will be in the range [0-6] (our semantic values) 
    scaled_relevance = relevance.to_f/6.to_f #scaled from [0-6] in the range [0-1]
    
    #printing values
    # puts("vertexMatch is [0-6]:: #{vert_match}")
    # puts("edgeWithoutSyn Match is [0-6]:: #{edge_without_syn}")
    # puts("edgeWithSyn Match is [0-6]:: #{edge_with_syn}")
    # puts("edgeDiffType Match is [0-6]:: #{edge_diff_type}")
    # puts("doubleEdge Match is [0-6]:: #{double_edge}")
    # puts("doubleEdge with syntax Match is [0-6]:: #{double_edge_with_syn}")
    # puts("relevance [0-6]:: #{relevance}")
    # puts("scaled relevance on [0-1]:: #{scaled_relevance}")
    # puts("*************************************************")
    return scaled_relevance
end
end