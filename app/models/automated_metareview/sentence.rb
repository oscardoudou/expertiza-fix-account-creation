
class Sentence
  #attr_accessor auto creates the get and set methods for the following attributes
  attr_accessor :ID, :sentence, :vertices, :num_vertices, :edges, :num_edges, :avg_similarity, :cluster_ID, :flag_covered, :sent_cover_num
  def initialize(id, verts, edges, num_verts, num_edges)
    @ID = id
    @vertices = verts
    @edges = edges
    @num_vertices = num_verts
    @num_edges = num_edges
    @avg_similarity = 0
    @flag_covered = false
    @sent_cover_num = 0
  end
end
