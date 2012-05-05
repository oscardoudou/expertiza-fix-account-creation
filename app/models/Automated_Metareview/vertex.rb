class Vertex
  #attr_accessor auto creates the get and set methods for the following attributes
  attr_accessor :name, :type, :frequency, :index, :nodeID, :state, :label, :parent, :posTag
  def initialize(vertexName, vertexType, indexValue, state, lab, par, posTag)
    @name = vertexName
    @type = vertexType
    @frequency = 0
    @index = indexValue
    @nodeID = -1 #to identify if the id has been set or not
    @state = state #they are not negated by default
    
    #for semantic role labelling
    @label = lab
    @parent = par
    
    @posTag = posTag
  end
end

# instance =  Vertex.new("hello", 1, 1, 0, 1, 1, 1)
# puts "vertex name #{instance.name}"
