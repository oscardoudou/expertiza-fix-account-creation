class Sentence
  attr_accessor :ID, :vertices, :edges, :num_verts, :num_edges, :avg_similarity, :flag_covered, :cluster_ID
  def initialize(id, v, e, numv, nume)
    @ID = id
    @vertices = v
    @edges = e
    @num_verts = numv
    @num_edges = nume
    @avg_similarity = 0.0
    @flag_covered = false #to indicate coverage by a topic sentence
    @cluster_ID = -1
  end
end