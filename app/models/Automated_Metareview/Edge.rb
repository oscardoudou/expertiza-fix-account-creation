#require 'vertex'
#include Vertex
class Edge
  attr_accessor :edgeID, :type, :name, :index, :inVertex, :outVertex, :edgeMatch, :averageMatch, :frequency, :label
  
  def initialize(edgeName, edgeType)
    @name = edgeName
    @type = edgeType #1 - verb, 2 - adjective, 3-adverb 
    @averageMatch = 0.0 #initializing match to 0
    @frequency = 0  
    #initializing the number of matches for each metric value to 0
    @edgeMatch = Array.new
    @edgeMatch = [0, 0, 0, 0, 0]
  end
end

# instance =  Edge.new("funny-verb", 1)
# puts "edge name #{instance.name}"