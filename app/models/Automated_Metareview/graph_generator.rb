require 'Automated_Metareview/sentenceState'
require 'Automated_Metareview/Edge'
require 'Automated_Metareview/vertex'

class Graphgenerator
#include SentenceState 
#creating accessors for the instance variables
attr_accessor :vertices, :numVertices, :edges, :numEdges, :pipeline, :posTagger

#global variables
$vertices = Array.new
$edges = Array.new

=begin
   * generates the graph for the given review text and 
   * INPUT: an array of sentences for a review or a submission. Every row in 'text' contains one sentence.
   * type - tells you if it was a review or s submission
   * type = 1 - submission/past review
   * type = 2 - new review
=end
  
def generateGraph(text, posTagger, coreNLPTagger, forRelevance, forPatternIdentify)
  #initializing common arrays 
  @vertices = Array.new
  @numVertices = 0
  @edges = Array.new
  @numEdges = 0

  @posTagger = posTagger #part of speech tagger
  @pipeline = coreNLPTagger #dependency parsing
  puts "text.class #{text.class}.. text.length - #{text.length}"
  #iterate through the sentences in the text
  for i in (0..text.length-1)
    if(text[i].empty? or text[i] == "" or text[i].split(" ").empty?)
      next
    end
    unTaggedString = text[i].split(" ")
    puts "UnTagged String:: #{unTaggedString}"
    
    taggedString = @posTagger.get_readable(text[i])
    puts "taggedString:: #{taggedString}"
    
    #Initializing some arrays
    nouns = Array.new
    nCount = 0
    verbs = Array.new
    vCount = 0
    adjectives = Array.new
    adjCount = 0
    adverbs = Array.new
    advCount = 0
    
    parents = Array.new
    labels = Array.new
    
    #------------------------------------------#------------------------------------------
    #finding parents
    parents = findParents(text[i])
    parentCounter = 0
    #------------------------------------------#------------------------------------------
    #finding parents
    labels = findLabels(text[i])
    labelCounter = 0
    #------------------------------------------#------------------------------------------
    #find state
    sstate = SentenceState.new
    states_array = sstate.identifySentenceState(taggedString)
    states_counter = 0
    state = states_array[states_counter]
    states_counter += 1
    #------------------------------------------#------------------------------------------
    
    taggedString = taggedString.split(" ")
    puts "Tokenized String:: #{taggedString}"
    
    #iterate through the tokens
    for j in (0..taggedString.length-1)
      taggedToken = taggedString[j]
      plainToken = taggedToken[0...taggedToken.index("/")].to_s
      posTag = taggedToken[taggedToken.index("/")+1..taggedToken.length].to_s
      prevType = 0 #initlializing the prevyp    
      
      puts("**Value:: #{plainToken} LabelCounter:: #{labelCounter} ParentCounter:: #{parentCounter} POStag:: #{posTag}")
      #ignore periods
      if(plainToken == "." or taggedToken.include?("/POS") or (taggedToken.index("/") == taggedToken.length()-1) or (taggedToken.index("/") == taggedToken.length()-2))#this is for strings containinig "'s" or without POS
        next
      end
      puts "plainToken #{plainToken}"  
      #SETTING STATE
      #since the CC or IN are part of the following sentence segment, we set the STATE for that segment when we see a CC or IN
      if(taggedToken.include?("/CC"))#{//|| ps.contains("/IN")
        state = states_array[states_counter]
        states_counter+=1
        puts("^^^^NEW STATE:: #{state}")
      end
        
      #------------------------------------------
      #if the token is a noun
      if(taggedToken.include?("NN") or taggedToken.include?("PRP") or taggedToken.include?("IN") or taggedToken.include?("/EX") or taggedToken.include?("WP"))
        if(prevType == NOUN) #if(prevType == NOUN){//if prevtype is noun, combine the nouns
           nCount -= 1
           prevVertex = searchVertices(@vertices, nouns[nCount], i, 0) #fetching the previous vertex
           nouns[nCount] = nouns[nCount].to_s + " " + plainToken
           #checking if the previous noun concatenated with "s" already exists among the vertices
           if((nounVertex = getVertex(@vertices, nouns[nCount], i)) == nil) #getVertex(nouns[nCount], vertices)) == null){
              prevVertex.name = prevVertex.name.to_s + " " + plainToken #concatenating the nouns
              nounVertex = prevVertex #the current concatenated vertex will be considered
              if(labels[labelCounter] != "NMOD" or labels[labelCounter] != "PMOD")#resetting labels for the concatenated vertex
                nounVertex.label = labels[labelCounter]
              end
              fAppendedVertex = 1
              #no incrementing the number of vertices for appended vertices
           end#if the vertex already exists, just use nounVertex - the returned vertex for ops.          
        #if the previous token is not a noun
        else
           puts("Noun here 2:: #{plainToken}");
           nouns[nCount] = plainToken #this is checked for later on
           nounVertex = searchVertices(@vertices, plainToken, i, 1)
           if(nounVertex == nil) #the string doesn't already exist
              @vertices[@numVertices] = Vertex.new(nouns[nCount], NOUN, i, state, labels[labelCounter], parents[parentCounter], posTag)
              nounVertex = @vertices[@numVertices] #the newly formed vertex will be considered
              @numVertices+=1
           end
        end #end of if prevType was noun
      
        #if an adjective was found earlier, we add a new edge
        if(prevType == ADJ)
            #set previous noun's property to null, if it was set, if there is a noun following the adjective
            if(nCount >= 0) #delete the edge created and add a new edge
              if(nCount == 0)
                v1 = searchVertices(@vertices, nouns[nCount], i, 0) #fetching the previous noun
              else
                v1 = searchVertices(@vertices, nouns[nCount-1], i, 0) #fetching the previous noun
              end
              
              v2 = searchVertices(@vertices, adjectives[adjCount-1], i, 0) #fetching the previous adjective             
              #if such an edge exists - DELETE IT
              if(!v1.nil? and !v2.nil? and (e = searchEdgesToSetNull(@edges, v1, v2, i)) != -1) #-1 is when no such edge exists
                @edges[e] = nil #setting the edge to null
                @numEdges-=1 #deducting an edge count
              end             
            end
            #if this noun vertex was encountered for the first time, nCount < 1,
            #so do adding of edge outside the if condition            
            #add a new edge with v1 as the adjective and v2 as the new noun
            v1 = searchVertices(@vertices, adjectives[adjCount-1], i, 0)
            v2 = nounVertex
            #if such an edge did not already exist
            if(!v1.nil? and !v2.nil? and (e = searchEdges(@edges, v1, v2, i)) == -1)
              @edges[@numEdges] = Edge.new("noun-property",VERB)
              @edges[@numEdges].inVertex = v1
              @edges[@numEdges].outVertex = v2
              @edges[@numEdges].index = i
              @numEdges+=1
            end
         end
         #a noun has been found and has established a verb as an invertex and such an edge doesnt already previously exist
          if(vCount >= 1 and fAppendedVertex == 0) 
            #add edge only when a fresh vertex is created not when existing vertex is appended to
            #System.out.println("here2 verb name "+verbs[vCount-1] +" i"+i);
            v1 = searchVertices(@vertices, verbs[vCount-1], i, 0)
            v2 = nounVertex
            #System.out.println("check edge "+v1.name +" - "+v2.name);
            #if such an edge does not already exist add it
            if(!v1.nil? and !v2.nil? and (e = searchEdges(@edges,v1, v2, i)) == -1)
              #System.out.println("adding edge:: "+v1.name+" - "+v2.name);
              @edges[@numEdges] = Edge.new("verb", VERB)             
              @edges[@numEdges].inVertex = v1 #for vCount = 0
              @edges[@numEdges].outVertex = v2
              @edges[@numEdges].index = i
              @numEdges+=1
            end
          end
          fAppendedVertex = 0 #resetting the appended vertex flag
          prevType = NOUN
          nCount+=1
      #------------------------------------------
      #if the string is an adjective
      #adjectives are vertices but they are not connected by an edge to the nouns, instead they are the noun's properties
      elsif(taggedToken.include?("/JJ"))                  
        adjective = nil
        if(prevType == ADJ) #combine the adjectives
          if(adjCount >= 1)
            adjCount = adjCount - 1
            prevVertex = searchVertices(vertices, adjectives[adjCount], i, 0) #fetching the previous vertex
            adjectives[adjCount] = adjectives[adjCount] + " " + plainToken              
            #if the concatenated vertex didn't already exist
            if((adjective = getVertex(@vertices, adjectives[adjCount], i)).nil?)
              prevVertex.name = prevVertex.name +" " + plainToken
              adjective = prevVertex #set it as "adjective" for further execution
              if(labels[labelCounter] != "NMOD" or labels[labelCounter] != "PMOD") #resetting labels for the concatenated vertex
                adjective.label = labels[labelCounter]
              end
            end
          end
        else #new adjective vertex
          adjectives[adjCount] = plainToken
          if((adjective = getVertex(@vertices, plainToken, i)).nil?) #the string doesn't already exist
            @vertices[@numVertices] = Vertex.new(adjectives[adjCount], ADJ, i, state, labels[labelCounter], parents[parentCounter], posTag)
            adjective = @vertices[@numVertices]
            @numVertices+=1
          end
        end
          
        #by default associate the adjective with the previous/latest noun and if there is a noun following it immediately, then remove the property from the older noun (done under noun condition)
        if(nCount >= 0)
          #gets the previous noun to form the edge
          if(nCount == 0)
            v1 = searchVertices(@vertices, nouns[nCount], i, 0)
          else
            v1 = searchVertices(@vertices, nouns[nCount-1], i, 0)
          end
            
          v2 = adjective
          #if such an edge does not already exist add it
          if(!v1.nil? and !v2.nil? and (e = searchEdges(@edges, v1, v2, i)) == -1)
            @edges[@numEdges] = Edge.new("noun-property",VERB)
            @edges[@numEdges].inVertex = v1
            @edges[@numEdges].outVertex = v2
            @edges[@numEdges].index = i
            @numEdges+=1             
          end
        end
        prevType = ADJ;
        adjCount+=1
        #end of if condition for adjective
        #------------------------------------------
        #if the string is a verb or a modal//length condition for verbs is, be, are...
        elsif(taggedToken.include?("/VB") or taggedToken.include?("MD"))
          puts("***VB #{plainToken} index:: #{i}")
          verbVertex = nil
          if(prevType == VERB) #combine the verbs            
            vCount = vCount - 1
            prevVertex = searchVertices(@vertices, verbs[vCount], i, 0) #fetching the previous vertex
            verbs[vCount] = verbs[vCount] + " " + plainToken            
            #if the concatenated vertex didn't already exist
            if((verbVertex = getVertex(@vertices, verbs[vCount], i)) == nil)
              prevVertex.name = prevVertex.name + " " + plainToken
              verbVertex = prevVertex #concatenated vertex becomes the new verb vertex
              if(labels[labelCounter] != "NMOD" or labels[labelCounter] != "PMOD")#resetting labels for the concatenated vertex
                verbVertex.label = labels[labelCounter]
              end
            end
            fAppendedVertex = 1
          else
            verbs[vCount] = plainToken
            if((verbVertex = getVertex(@vertices, plainToken, i)) == nil)
              #System.out.println("setting vertex "+s + "numVertices "+numVertices);
              @vertices[@numVertices] = Vertex.new(plainToken, VERB, i, state, labels[labelCounter], parents[parentCounter], posTag)
              verbVertex = @vertices[@numVertices] #newly created verb vertex will be considered in the future
              @numVertices+=1
            end
          end
          
          #if an adverb was found earlier, we set that as the verb's property
          if(prevType == ADV)
            #System.out.println("verb "+s +" advcount "+advCount);
            #set previous verb's property to null, if it was set, if there is a verb following the adverb
            if(vCount >= 0)
              if(vCount == 0)
                v1 = searchVertices(@vertices, verbs[vCount], i, 0) #fetching the previous verb
              else
                v1 = searchVertices(@vertices, verbs[vCount-1], i, 0) #fetching the previous verb
              end
              v2 = searchVertices(@vertices, adverbs[advCount-1], i, 0) #fetching the previous adverb             
              #if such an edge exists - DELETE IT
              if(!v1.nil? and !v2.nil? and (e = searchEdges(@edges, v1, v2, i)) != -1)
                @edges[e] = nil #setting the edge to null
                @numEdges-=1 #deducting an edge count
              end
            end
            #if this verb vertex was encountered for the first time, vCount < 1,
            #so do adding of edge outside the if condition
            #add a new edge with v1 as the adverb and v2 as the new verb
            v1 = searchVertices(@vertices, adverbs[advCount-1], i, 0)
            v2 = verbVertex
            #if such an edge did not already exist
            if(!v1.nil? and !v2.nil? and (e = searchEdgesToSetNull(@edges, v1, v2, i)) == -1)
              #System.out.println("Adding edge for adverb:: "+adverbs[advCount-1]);
              @edges[@numEdges] = Edge.new("verb-property",VERB)
              @edges[@numEdges].inVertex = v1
              @edges[@numEdges].outVertex = v2
              @edges[@numEdges].index = i
              @numEdges+=1 
            end
            #advCount--;//having assigned the adverb, we can remove it from the list
          end
          
          #making the previous noun, one of the vertices of the verb edge
          if(nCount >= 1 and fAppendedVertex == 0) #&& vertices[i]!=null && vertices[i][numVertices - 1]!= null){//third condition is to avoid re-assignment
            #gets the previous noun to form the edge
            v1 = searchVertices(@vertices, nouns[nCount-1], i, 0)
            v2 = verbVertex
            #if such an edge does not already exist add it
            #System.out.println("check edge "+v1.name +" - "+v2.name);
            if(!v1.nil? and !v2.nil? and (e = searchEdges(@edges, v1, v2, i)) == -1)
              #System.out.println("adding edge "+v1.name +" - "+v2.name);
              @edges[@numEdges] = Edge.new("verb",VERB)
              @edges[@numEdges].inVertex = v1 #for nCount = 0;
              @edges[@numEdges].outVertex = v2 #the verb
              @edges[@numEdges].index = i
              @numEdges+=1
            end
          end
          #System.out.println("edge "+edges[i][numEdges-1].inVertex.name +" - "+edges[i][numEdges-1].outVertex.name);
          fAppendedVertex = 0 #resetting the flag
          prevType = VERB
          vCount+=1
        #------------------------------------------ 
        #if the string is an adverb
        elsif(taggedToken.include?("RB"))
          puts("Adverb #{plainToken}")                  
          adverb = nil
          if(prevType == ADV) #appending to existing adverb
            if(advCount >= 1)
              advCount = advCount - 1
            end
            prevVertex = searchVertices(@vertices, adverbs[advCount], i, 0) #fetching the previous vertex
            adverbs[advCount] = adverbs[advCount] + " " + plainToken
            #if the concatenated vertex didn't already exist
            if((adverb = getVertex(vertices, adverbs[advCount], i)) == nil)
              prevVertex.name = prevVertex.name + " " + plainToken
              adverb = prevVertex #setting it as "adverb" for further computation
              if(labels[labelCounter] != "NMOD" or labels[labelCounter] != "PMOD") #resetting labels for the concatenated vertex
                adverb.label = labels[labelCounter]
              end
            end
          else #else creating a new vertex
            adverbs[advCount] = plainToken
            if((adverb = getVertex(@vertices, plainToken, i)) == nil)
              @vertices[@numVertices] = Vertex.new(adverbs[advCount], ADV, i, state, labels[labelCounter], parents[parentCounter], posTag);
              adverb = @vertices[@numVertices]
              @numVertices+=1
            end
          end
          
          #by default associate it with the previous/latest verb and if there is a verb following it immediately, then remove the property from the verb
          if(vCount >= 0)
            #gets the previous noun to form the edge
            #System.out.println("Previous verb:: "+verbs[vCount-1]);
            #System.out.println("Adverb :: "+adverb.name);
            if(vCount == 0)
              v1 = searchVertices(@vertices, verbs[vCount], i, 0)
            else
              v1 = searchVertices(@vertices, verbs[vCount-1], i, 0)
            end
            v2 = adverb
            #if such an edge does not already exist add it
            if(!v1.nil? and !v2.nil? && (e = searchEdges(@edges, v1, v2, i)) == -1)
              #System.out.println("Adding edge for adverb:: "+s +" verb:: "+verbs[vCount-1])
              @edges[@numEdges] = Edge.new("verb-property",VERB)
              @edges[@numEdges].inVertex = v1 #for nCount = 0;
              @edges[@numEdges].outVertex = v2 #the verb
              @edges[@numEdges].index = i
              @numEdges+=1
            end
          end
          advCount+=1
          prevType = ADV
          #numVertices++;
        #end of if condition for adverb
        
        #incrementing counters for labels and parents
        labelCounter+=1
        parentCounter+=1
      end #end of if condition
      #------------------------------------------
    end #end of the for loop for the tokens
    #puts "here outside the for loop for tokens"
    nouns = nil
    verbs = nil
    adjectives = nil
    adverbs = nil
  end #end of number of sentences in the text
  # if(forRelevance == false and forPatternIdentify == true)
    # @edges = frequencyThreshold(@edges, @numEdges)
  # end  
  
  $edges = @edges
  $vertices = @vertices
  puts "here outside the loop where sentences are read"
  #setSemanticLabelsForEdges(@@vertices, @@edges)
  printGraph(@edges, @vertices)
  puts("Number of edges:: #{@numEdges}")
  puts("Number of vertices:: #{@numVertices}")
  return @numEdges
end #end of the graphGenerate method

#------------------------------------------#------------------------------------------#------------------------------------------

def searchVertices(list, s, index, flag)
   puts("***** searchVertices:: #{s}")
    for i in (0..list.length-1)#(int i = 0;i < list.length; i++){
      if(!list[i].nil? and !s.nil?)      
        #if the vertex exists and in the same sentence (index)
        if(list[i].name.casecmp(s) == 0 and list[i].index == index)
          puts("***** Returning:: #{s}")
          return list[i]
        end
      end
    end
    return nil
end #end of the searchVertices method

#------------------------------------------#------------------------------------------#------------------------------------------

=begin
While checking if the complete vertex already exists and if it does incrementing its frequency.
Also, deleting substrings that would have formed full vertices early on, if any exist.
Looking for string 's' (from sentence with index 'index') in the set of vertices 'verts'
=end  
def getVertex(verts, s, index)
    position = 0;
    flag = 0;
    #if the string is nil
    if(s == nil)
      return nil
    end

    puts("***getVertex:: #{s}");

    for i in (0..verts.length-1)#(int i = 0;  i < verts.length; i++){
       #System.out.println("Comparing "+ verts[textNo][i].name.toLowerCase() +" - "+s.toLowerCase());
       if(!verts[i].nil? and verts[i].name.casecmp(s) == 0 and index.equal?(verts[i].index))
          puts("**** FOUND vertex:: #{s}")
          flag = 1
          position = i
          verts[i].frequency+=1

          #NULLIFY ALL VERTICES CONTAINING SUBSTRINGS OF THIS VERTEX IN THE SAME SENTENCE (verts[j].index == index)
          j = @numVertices - 1
          while j >= 0#for(int j = numVertices - 1;  j >= 0; j--){
            if(!verts[j].nil? and verts[j].index.equal?(index) and s.casecmp(verts[j].name) != 0 and !s.downcase().include?(verts[j].name.downcase()))
              verts[j] = nil
              @numVertices-=1
            end
            j-=1
          end #end of while loop
          break #break out of the for loop
       end #end of the if condition 
    end
    # end of the for loop
    
    if(flag == 1)
      return verts[position]
    else
      puts("***getVertex returning null")
      return nil
    end
end #end of the getVertex method 

#------------------------------------------#------------------------------------------#------------------------------------------

=begin
  Checks to see if an edge between vertices "in" and "out" exists.
  true - if an edge exists and false - if an edge doesn't exist
  edge[] list, vertex in, vertex out, int index
=end
def searchEdges(list, invertex, out, index)
  edgePos = -1
  puts("***** Searching for edge:: #{invertex.name} - #{out.name}")
  if(list.nil?)#if the list is null
    return edgePos
  end
  for i in (0..list.length-1) #(int i = 0;i < list.length; i++)
    if(!list[i].nil? and !list[i].inVertex.nil? and !list[i].outVertex.nil?)
      #checking for exact match with an edge
      puts("***** List[i]:: #{list[i].inVertex.name} - #{list[i].outVertex.name}")
      if(((list[i].inVertex.name.casecmp(invertex.name)==0 and list[i].inVertex.name.include?(invertex.name)) and (list[i].outVertex.name.casecmp(out.name)==0 or list[i].outVertex.name.include?(out.name))) or ((list[i].inVertex.name.casecmp(out.name)==0 or list[i].inVertex.name.include?(out.name)) and (list[i].outVertex.name.casecmp(invertex.name)==0 or list[i].outVertex.name.include?(invertex.name))))
        puts("***** Found edge! : index:: #{index} list[i].index:: #{list[i].index}")
        #if an edge was found
        edgePos = i #returning its position in the array
        #INCREMENT FREQUENCY IF THE EDGE WAS FOUND IN A DIFFERENT SENT. (CHECK BY MAINTAINING A TEXT NUMBER AND CHECKING IF THE NEW # IS DIFF FROM PREV #)
        if(index != list[i].index)
          list[i].frequency+=1
        end
        #System.out.println(list[i].inVertex.name+" - "+list[i].outVertex.name+" freq:: "+list[i].frequency);
        #System.out.println(in.name+" - "+out.name+" freq:: "+list[i].frequency);
      end
      
      #NULLIFY ALL VERTICES CONTAINING SUBSTRINGS OF THIS EDGE's In-VERTEX or OUt-VETEX IN THE SAME SENTENCE (list[j].index == index)
      j = @numEdges - 1
      while j >= 0 do #for(int j = numEdges - 1;  j >= 0; j--)
        if(!list[j].nil? and list[j].index == index)
          puts("@@@@ List[i]:: #{list[j].inVertex.name} - #{list[j].outVertex.name}")
          #when invertices are eq and out-verts are substrings or vice versa
          if(invertex.name.casecmp(list[j].inVertex.name) == 0 and out.name.casecmp(list[j].outVertex.name) != 0 and out.name.downcase().include?(list[j].outVertex.name.downcase()))
            puts("FOUND outvertex match for edge:: ")
            list[j] = nil
            @numEdges-=1
          #when in-vertices are eq and out-verts are substrings or vice versa
          elsif(!invertex.name.casecmp(list[j].inVertex.name)==0 and invertex.name.downcase().include?(list[j].inVertex.name.downcase()) and out.name.casecmp(list[j].outVertex.name)==0)
            puts("FOUND intvertex match for edge: ")
            list[j] = nil
            @numEdges-=1
          end
        end
        j-=1
      end #end of the while loop
    end#end of the if condition
   end #end of the for loop
  return edgePos
end # end of searchEdges
#------------------------------------------#------------------------------------------#------------------------------------------
def printGraph(edges, vertices)
  puts("*** List of vertices::")
  for j in (0..vertices.length-1) #(int j = 0; j < vertices.length; j++)
    if(!vertices[j].nil?)
      puts("@@@ Vertex:: #{vertices[j].name}")
      puts("*** Frequency:: #{vertices[j].frequency} State:: #{vertices[j].state}")
      puts("*** Label:: #{vertices[j].label} Parent:: #{vertices[j].parent}")
    end
  end
  puts("*******")
  puts("*** List of edges::")
  for j in (0..edges.length-1) #(int j = 0; j < edges.length; j++){
    if(!edges[j].nil? and !edges[j].inVertex.nil? and !edges[j].outVertex.nil?)
      puts("@@@ Edge:: #{edges[j].inVertex.name} & #{edges[j].outVertex.name}")
      puts("*** Frequency:: #{edges[j].frequency} State:: #{edges[j].inVertex.state} & #{edges[j].outVertex.state}")
      puts("*** Label:: #{edges[j].label}")
    end
  end
  puts("--------------")
end #end of printGraph method

#------------------------------------------#------------------------------------------#------------------------------------------
#Identifying parents and labels for the vertices
def findParents(t)
  puts "Inside findParents #{t}"
  
  unTaggedString = t.split(" ")
  parents = Array.new
  #  t = text[i]
  t = StanfordCoreNLP::Text.new(t) #the same variable has to be passed into the Textx.new method
  @pipeline.annotate(t)
  #for each sentence identify theparsed form of the sentence
  sentence = t.get(:sentences).toArray
  parsed_sentence = sentence[0].get(:collapsed_c_c_processed_dependencies)
    
  #iterating through the set of tokens and identifying each token's parent
  for j in (0..unTaggedString.length - 1)
    if(isPunct(unTaggedString[j]))
      next
    end
    if(isContainPunct(unTaggedString[j]))
      unTaggedString[j] = isContainPunct(unTaggedString[j])
      next
    end
    puts "unTaggedString[j] #{unTaggedString[j]}"
    pat = parsed_sentence.getAllNodesByWordPattern(unTaggedString[j])
    pat = pat.toArray
    parent = parsed_sentence.getParents(pat[0]).toArray
    puts "parent of #{unTaggedString[j]} is #{parent[0]}"
    if(!parent[0].nil?)
      parents[j] =  (parent[0].to_s)[0..(parent[0].to_s).index("-")-1]#extracting the name of the parent (since it is in the foramt-> "name-POS")
    else
      parents[j] = nil
    end
  end
  
  #printing parents
  for j in (0..parents.length - 1)
    puts parents[j]
  end
  return parents
end #end of findParents method
#------------------------------------------#------------------------------------------#------------------------------------------
#Identifying parents and labels for the vertices
def findLabels(t)
  puts "Inside findLabels #{t}"
  unTaggedString = t.split(" ")
  t = StanfordCoreNLP::Text.new(t)
  @pipeline.annotate(t)
  #for each sentence identify theparsed form of the sentence
  sentence = t.get(:sentences).toArray
  parsed_sentence = sentence[0].get(:collapsed_c_c_processed_dependencies)    
  labels = Array.new
  labelCounter = 0
  govDep = parsed_sentence.typedDependencies.toArray
  #for each untagged token
  for j in (0..unTaggedString.length - 1)
    unTaggedString[j].gsub!(".", "")
    unTaggedString[j].gsub!(",", "")
    puts "Label for #{unTaggedString[j]}"
    #identify its corresponding position in govDep and fetch its label
    for k in (0..govDep.length - 1)
      #puts "Comparing with #{govDep[k].dep.value()}"
      if(govDep[k].dep.value() == unTaggedString[j])
        labels[j] = govDep[k].reln.getShortName()
        puts labels[j]
        labelCounter+=1
        break
      end
    end
  end
  #printing labels
  for j in (0..labels.length - 1)
    puts labels[j]
  end
  return labels
end # end of findLabels method
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
   * Setting semantic labels for edges based on the labels vertices have with their parents
=end
def setSemanticLabelsForEdges(vertices, edges)
  for i in (0.. vertices.length - 1) #(int i = 0; i < vertices.length; i++)
    if(!vertices[i].nil? and !vertices[i].parent.nil?) #parent = null for ROOT
        #System.out.println("**Parent for::"+vertices[i].name);
        #search for the parent vertex
        for i in (0..vertices.length - 1) #(int j = 0; j < vertices.length; j++){
          if(!vertices[j].nil? and (vertices[j].name.casecmp(vertices[i].parent) == 0 or 
                vertices[j].name.downcase().contains(vertices[i].parent.downcase()))) #{
            puts("**Parent:: #{vertices[j].name}")
            parent = vertices[j]
            break #break out of search for the parent
          end
        end
        if(!parent.nil?)#{
          #check if an edge exists between vertices[i] and the parent
          for k in (0..edges.length - 1)#(int k = 0; k < edges.length; k++){
            if(!edges[k].nil? and !edges[k].inVertex.nil? and !edges[k].outVertex.nil?)#{
              if((edges[k].inVertex.name.equal?(vertices[i].name) and edges[k].outVertex.name.equal?(parent.name)) or (edges[k].inVertex.name.equal?(parent.name) and edges[k].outVertex.name.equal?(vertices[i].name)))#{
                #set the role label
                if(edges[k].label.nil?)
                  edges[k].label = vertices[i].label
                elsif(!edges[k].label.nil? and (edges[k].label == "NMOD" or edges[k].label == "PMOD") and (vertices[i].label != "NMOD" or vertices[i].label != "PMOD"))
                  edges[k].label = vertices[i].label
                end
              end  
            end
          end
        end#end of if paren.nil? condition
    end  
  end #end of for loop
end #end of setSemanticLabelsForEdges method 

end # end of the class GraphGenerator
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
 Identifying frequency of edges and pruning out edges that do no meet the threshold conditions 
=end
def frequencyThreshold(edges, num)
  puts "inside frequency threshold! :: num #{num}"
  #freqEdges maintains the top frequency edges from ALPHA_FREQ to BETA_FREQ
  freqEdges = Array.new #from alpha = 3 to beta = 10
  #iterating through all the edges
  for j in (0..num-1) #(int j = 0; j < num; j++)
    if(!edges[j].nil?)#{       
      if(edges[j].frequency <= BETA_FREQ and edges[j].frequency >= ALPHA_FREQ and !freqEdges[edges[j].frequency-1].nil?)#{
        for i in (0..freqEdges[edges[j].frequency-1].length - 1)#iterating to find i for which freqEdges is null
          if(!freqEdges[edges[j].frequency-1][i].nil?)
            break
          end
        end
        freqEdges[edges[j].frequency-1][i] = edges[j]
      end
    end
  end
  selectedEdges = Array.new  
  #Selecting only those edges that satisfy the frequency condition [between ALPHA and BETA]
  j = BETA_FREQ-1
  while j >= ALPHA_FREQ-1 do #(int j = BETA_FREQ-1; j >= ALPHA_FREQ-1; j--) #&& maxSelected < MAX
    if(!freqEdges[j].nil?)
      for i in (0..num-1)#(int i = 0; freqEdges[j][i] != null && i < num; i++){//&& maxSelected < MAX
        if(!freqEdges[j][i].nil?)
          selectedEdges[maxSelected] = freqEdges[j][i]
          maxSelected+=1
        end
      end
    end
    j-=1
  end
    
  if(maxSelected != 0)
    @numEdges = maxSelected #replacing numEdges with the number of selected edges
  end
  return selectedEdges
end
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
 Checking if "str" is a punctuation mark like ".", ",", "?" etc. 
=end
def isPunct(str)
  if(str == "." or str == "," or str == "?" or str == "!" or str == ";" or str == ":")
    return true
  else
    return false
  end 
end  
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
 Checking if "str" is a punctuation mark like ".", ",", "?" etc. 
=end
def isContainPunct(str)
  if(str.include?".")
    str.gsub!(".","")
  elsif(str.include?",")
    str.gsub!(",","")
  elsif(str.include?"?")
    str.gsub!("?","")
  elsif(str.include?"!")
    str.gsub!("!","") 
  elsif(str.include?";")
    str.gsub(";","")
  elsif(str.include?":")
    str.gsub!(":","")
  elsif(str.include?"(")
    str.gsub!("(","")
  elsif(str.include?")")
    str.gsub!(")","")
  elsif(str.include?"[")
    str.gsub!("[","")
  elsif(str.include?"]")
    str.gsub!("]","")  
  end 
  return str
end 

#testing
=begin
posTagger = EngTagger.new
pipeline =  StanfordCoreNLP.load(:tokenize, :ssplit, :pos, :lemma, :parse, :ner, :dcoref)
text = Array.new
text[0] = "Alice chased the big fat cat."
puts "#{text}"
instance = Graphgenerator.new
instance.generateGraph(text, posTagger, pipeline)
=end