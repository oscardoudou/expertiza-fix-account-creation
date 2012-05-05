require 'Automated_Metareview/wordnetBasedSimilarity'
require 'Automated_Metareview/graphGenerate'

class DegreeOfRelevance
  
#creating accessors for the instance variables
attr_accessor :vertexMatch
@@Edges = Array.new
=begin
  Identifies relevance between a review and a submission
=end  
def getRelevance(reviews, submissions, numReviews, posTagger, coreNLPTagger) #double dimensional arrays that contain the submissions and the reviews respectively
  reviewVertices = nil
  reviewEdges = nil
  submVertices = nil
  submEdges = nil
  numRevVert = 0
  numRevEdg = 0 
  numSubVert = 0 
  numSubEdg = 0
  vertMatch = 0.0
  edgeWithoutSyn = 0.0
  edgeWithSyn = 0.0
  edgeDiffType = 0.0
  doubleEdge = 0.0
  doubleEdgeWithSyn = 0.0
  plagiarism = false
  
    #since Reviews and Submissions "should" contain the same number of records review - submission pairs
    g = Graphgenerator.new
    #generating review's graph
    g.generateGraph(reviews, posTagger, coreNLPTagger, true, false)
    reviewVertices = g.vertices
    reviewEdges = g.edges
    numRevVert = g.numVertices
    numRevEdg = g.numEdges
    
    #declaring constants that can be used for class prediction
    @@Edges = g.edges
      
    #generating the submission's graph
    g.generateGraph(submissions, posTagger, coreNLPTagger, true, false)
    submVertices = g.vertices
    submEdges = g.edges
    numSubVert = g.numVertices
    numSubEdg = g.numEdges
      
    vertMatch = compareVertices(posTagger, reviewVertices, submVertices, numRevVert, numSubVert)
    edgeWithoutSyn = compareEdgesnNonSyntaxDiff(reviewEdges, submEdges, numRevEdg, numSubEdg)
    edgeWithSyn = compareEdgesSyntaxDiff(reviewEdges, submEdges, numRevEdg, numSubEdg)
    edgeDiffType = compareEdgesDiffTypes(reviewEdges, submEdges, numRevEdg, numSubEdg)
    edgeMatch = (edgeWithoutSyn + edgeWithSyn + edgeDiffType)/3
    doubleEdge = compareSVOEdges(reviewEdges, submEdges, numRevEdg, numSubEdg)
    doubleEdgeWithSyn = compareSVODiffSyntax(reviewEdges, submEdges, numRevEdg, numSubEdg)
    doubleEdgeMatch = (doubleEdge + doubleEdgeWithSyn)/2
      
    #differently weighted cases
    #tweak this!!
    alpha = 0.55
    beta = 0.35
    gamma = 0.1 #alpha > beta > gamma
    relevance = (alpha.to_f * vertMatch) + (beta * edgeMatch) + (gamma * doubleEdgeMatch) #case1's value will be in the range [0-6] (our semantic values) 
 
    puts("vertexMatch is: #{vertMatch}")
    puts("edgeWithoutSyn Match is:: #{edgeWithoutSyn}")
    puts("edgeWithSyn Match is:: #{edgeWithSyn}")
    puts("edgeDiffType Match is:: #{edgeDiffType}")
    puts("doubleEdge Match is:: #{doubleEdge}")
    puts("doubleEdge with syntax Match is:: #{doubleEdgeWithSyn}")
    puts("relevance:: #{relevance}")
    puts("*************************************************")
    return relevance
end  
=begin
   * every vertex is compared with every other vertex
   * Compares the vertices from across the two graphs to identify matches and quantify various metrics
   * v1- vertices of the submission/past review and v2 - vertices from new review 
=end
def compareVertices(posTagger, rev, subm, numRevVert, numSubVert)
  puts("****Inside compareVertices:: rev.length:: #{numRevVert} subm.length:: #{numSubVert}")
  #for double dimensional arrays, one of the dimensions should be initialized
  @vertexMatch = Array.new(numRevVert){Array.new}
  wnet = WordnetBasedSimilarity.new
  cumVertexMatch = 0.0
  count = 0
  max = 0.0
  flag = 0
    
  for i in (0..numRevVert - 1) #(int i = 0;i < numRevVert; i++){
    if(!rev.nil? and !rev[i].nil?)
      rev[i].nodeID = i
      #skipping frequent words from vertex comparison
      if(wnet.isFrequentWord(rev[i].name))
        puts("Skipping frequent word:: #{rev[i].name}")
        next #ruby equivalent for continue 
      end
      #looking for the best match
      #j tracks every element in the set of all vertices, some of which are null
      for j in (0..numSubVert - 1)
        if(!subm[j].nil?)
          subm[j].nodeID = j #node id for submissions is given using 'subCount'
          @vertexMatch[i][j] = wnet.compareStrings(rev[i], subm[j])          
          #only if the "if" condition is satisfied, since there could be null objects in between and you dont want unnecess. increments
          flag = 1
          if(@vertexMatch[i][j] > max)
            max = @vertexMatch[i][j]
          end
            puts(@vertexMatch[i][j])
        end
      end #end of for loops
      if(flag != 0)#if the review edge had any submission edges with which it was matched, since not all S-V edges might have corresponding V-O edges to match with
        puts("**** Best match for:: #{rev[i].name}-- #{max}")
        cumVertexMatch = cumVertexMatch + max
        count+=1
        max = 0.0 #re-initialize
        flag = 0
      end
    end #end of if condition
  end #end of for loop

  avgMatch = 0.0
  if(count > 0)
    avgMatch = cumVertexMatch/ count
  end
  
  puts("Cumulative vertex match:: #{avgMatch}")
  return avgMatch  
end #end of compareVertices

#------------------------------------------#------------------------------------------
=begin 
   * SAME TYPE COMPARISON!!
   * Compares the edges from across the two graphs to identify matches and quantify various metrics
   * compare SUBJECT-VERB edges with SUBJECT-VERB matches
   * where SUBJECT-SUBJECT and VERB-VERB or VERB-VERB and OBJECT-OBJECT comparisons are done
=end
def compareEdgesnNonSyntaxDiff( rev, subm, numRevEdg, numSubEdg)
  puts("*****Inside compareEdgesnNonSyntaxDiff numRevEdg:: #{numRevEdg} numSubEdg:: #{numSubEdg}")   
  bestSV_SVMatch = Array.new(numRevEdg){Array.new}
  cumEdgeMatch = 0.0
  count = 0
  max = 0.0
  flag = 0
  wnet = WordnetBasedSimilarity.new
  for i in (0..numRevEdg - 1) #(int i = 0;i < numRevEdg; i++){
    if(!rev[i].nil? and rev[i].inVertex.nodeID != -1 and rev[i].outVertex.nodeID != -1)
    #skipping edges with frequent words for vertices
    if(wnet.isFrequentWord(rev[i].inVertex.name) and wnet.isFrequentWord(rev[i].outVertex.name))
      puts("Skipping edge::#{rev[i].inVertex.name} - #{rev[i].outVertex.name}")
      next
    end
    #looking for best matches
    for j in (0..numSubEdg - 1) #(int j = 0; j < numSubEdg; j++){
      #comparing in-vertex with out-vertex to make sure they are of the same type
      if(!subm[j].nil? && subm[j].inVertex.nodeID != -1 && subm[j].outVertex.nodeID != -1)
        if(rev[i].inVertex.type == subm[j].inVertex.type && rev[i].outVertex.type == subm[j].outVertex.type)
          puts("rev[i].inVertex.name #{rev[i].inVertex.name} and subm[j].inVertex.name #{subm[j].inVertex.name} ::val:: #{@vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID]}")
          puts("rev[i].outVertex.name #{rev[i].outVertex.name} && subm[j].outVertex.name #{subm[j].outVertex.name} ::val:: #{@vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID]}")
          if(!rev[i].label.nil?)
            puts("rev[i].label #{rev[i].label}")
            if(!subm[j].label.nil?)
              puts("subm[j].label #{subm[j].label}")
              #--Only vertex matches
              bestSV_SVMatch[i][j] = (@vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID] + @vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID])/2
              #--Vertex and SRL
              bestSV_SVMatch[i][j] = bestSV_SVMatch[i][j]/ compareLabels(rev[i], subm[j])
              #--Only SRL matches
              #bestSV_SVMatch[i][j] = (double)compareLabels(rev[i].label, subm[j].label);
              
              flag = 1
              if(bestSV_SVMatch[i][j] > max)
                max = bestSV_SVMatch[i][j]
              end
            end
          end
        end
      end
    end #end of for loop for 'j'
        
    if(flag != 0) #if the review edge had any submission edges with which it was matched, since not all S-V edges might have corresponding V-O edges to match with
      puts("**** Best match for:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name} -- #{max}")
      cumEdgeMatch = cumEdgeMatch + max
      count+=1
      max = 0.0#re-initialize
      flag = 0
      end
    end
  end #end of 'for' loop for 'i'
  avgMatch = 0.0
  if(count > 0)
    avgMatch = cumEdgeMatch/ count
  end
  
  puts("Cumulative edge (without syn) match:: #{avgMatch}")
  return avgMatch
end
#------------------------------------------#------------------------------------------
=begin
   * SAME TYPE COMPARISON!!
   * Compares the edges from across the two graphs to identify matches and quantify various metrics
   * compare SUBJECT-VERB edges with VERB-OBJECT matches and vice-versa
   * where SUBJECT-OBJECT and VERB_VERB comparisons are done - same type comparisons!!
=end

def compareEdgesSyntaxDiff(rev, subm, numRevEdg, numSubEdg)
  puts("*****Inside compareEdgesSyntaxDiff :: numRevEdg :: #{numRevEdg} numSubEdg:: #{numSubEdg}")    
  bestSV_VSMatch = Array.new(numRevEdg){Array.new}
  cumEdgeMatch = 0.0
  count = 0
  max = 0.0
  flag = 0
  wnet = WordnetBasedSimilarity.new  
  for i in (0..numRevEdg - 1)#(int i = 0;i < numRevEdg; i++){
    if(!rev[i].nil? and rev[i].inVertex.nodeID != -1 and rev[i].outVertex.nodeID != -1)
      
      #skipping frequent word
      if(wnet.isFrequentWord(rev[i].inVertex.name) and wnet.isFrequentWord(rev[i].outVertex.name))
        puts("Skipping edge:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name}")
        next
      end
      
      for j in (0..numSubEdg - 1) #(int j = 0; j < numSubEdg; j++)
        if(!subm[j].nil? and subm[j].inVertex.nodeID != -1 and subm[j].outVertex.nodeID != -1)
          if(rev[i].inVertex.type == subm[j].outVertex.type and rev[i].outVertex.type == subm[j].inVertex.type and
            !@vertexMatch[rev[i].inVertex.nodeID][subm[j].outVertex.nodeID].nil? and !@vertexMatch[rev[i].outVertex.nodeID][subm[j].inVertex.nodeID].nil?)
            puts("rev[i].inVertex.name #{rev[i].inVertex.name} && subm[j].outVertex.name #{subm[j].outVertex.name} ::val:: #{@vertexMatch[rev[i].inVertex.nodeID][subm[j].outVertex.nodeID]}")
            puts("rev[i].outVertex.name #{rev[i].outVertex.name} && subm[j].inVertex.name #{subm[j].inVertex.name} ::val:: #{@vertexMatch[rev[i].outVertex.nodeID][subm[j].inVertex.nodeID]}")
            if(!rev[i].label.nil?)
              puts("rev[i].label #{rev[i].label}")
            end
            if(!subm[j].label.nil?)
              puts("subm[j].label #{subm[j].label}")
            end
            #--Only vertex matches
            bestSV_VSMatch[i][j] = (@vertexMatch[rev[i].inVertex.nodeID][subm[j].outVertex.nodeID] + @vertexMatch[rev[i].outVertex.nodeID][subm[j].inVertex.nodeID])/2
            #--Vertex and SRL 
            #**it is likely that these edges will always have different labels due to the nature and order of comparison of edges
            #S-V edges are likely to be SUBJ while V-O edges could be OBJ and hence different labels are frequent
            #bestSV_VSMatch[i][j] = (double)bestSV_VSMatch[i][j]/ (double)compareLabels(rev[i], subm[j]);
            #--Only SRL
            #bestSV_VSMatch[i][j] = (double)compareLabels(rev[i].label, subm[j].label);
            flag = 1
            if(bestSV_VSMatch[i][j] > max)
              max = bestSV_VSMatch[i][j]
            end
          end
        end #end of the if condition
      end #end of the for loop for the submission edges     
          
      if(flag != 0)#if the review edge had any submission edges with which it was matched, since not all S-V edges might have corresponding V-O edges to match with
        puts("**** Best match for:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name}-- #{max}")
        cumEdgeMatch = cumEdgeMatch + max
        count+=1
        max = 0.0 #re-initialize
        flag = 0
      end
        
    end #end of the if condition
  end #end of the for loop for the review
   
  avgMatch = 0.0
  if(count > 0)
    avgMatch = cumEdgeMatch/count
  end
  puts("Cumulative edge (diff syntax) match:: #{avgMatch}")
  return avgMatch
end  #end of the method
#------------------------------------------#------------------------------------------
=begin
   DIFFERENT TYPE COMPARISON!!
   * Compares the edges from across the two graphs to identify matches and quantify various metrics
   * compare SUBJECT-VERB edges with VERB-OBJECT matches and vice-versa
   * SUBJECT-VERB, VERB-SUBJECT, OBJECT-VERB, VERB-OBJECT comparisons are done! 
=end
def compareEdgesDiffTypes(rev, subm, numRevEdg, numSubEdg)
  puts("*****Inside compareEdgesDiffTypes :: numRevEdg :: #{numRevEdg} numSubEdg:: #{numSubEdg}")   
  bestSV_VSMatch = Array.new(numRevEdg){Array.new}
  cumEdgeMatch = 0.0
  count = 0
  max = 0.0
  flag = 0
  wnet = WordnetBasedSimilarity.new  
  for i in (0..numRevEdg - 1) #(int i = 0;i < numRevEdg; i++){
    if(!rev[i].nil? and rev[i].inVertex.nodeID != -1 and rev[i].outVertex.nodeID != -1)
      #skipping edges with frequent words for vertices
      if(wnet.isFrequentWord(rev[i].inVertex.name) and wnet.isFrequentWord(rev[i].outVertex.name))
        puts("Skipping edge:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name}")
        next
      end
      #identifying best match for edges
      for j in (0..numSubEdg - 1) #(int j = 0; j < numSubEdg; j++){
        if(!subm[j].nil? and subm[j].inVertex.nodeID != -1 and subm[j].outVertex.nodeID != -1)
          #for S-V with S-V or V-O with V-O
          if(rev[i].inVertex.type == subm[j].inVertex.type and rev[i].outVertex.type == subm[j].outVertex.type and
            !@vertexMatch[rev[i].inVertex.nodeID][subm[j].outVertex.nodeID].nil? and !@vertexMatch[rev[i].outVertex.nodeID][subm[j].inVertex.nodeID].nil?)
            puts("rev[i].inVertex.name #{rev[i].inVertex.name} && subm[j].outVertex.name #{subm[j].outVertex.name} ::val:: #{@vertexMatch[rev[i].inVertex.nodeID][subm[j].outVertex.nodeID]}")
            puts("rev[i].outVertex.name #{rev[i].outVertex.name} && subm[j].inVertex.name #{subm[j].inVertex.name} ::val:: #{@vertexMatch[rev[i].outVertex.nodeID][subm[j].inVertex.nodeID]}")
            if(!rev[i].label.nil?)
              puts("rev[i].label #{rev[i].label}")
            end
            if(!subm[j].label.nil?)
              puts("subm[j].label #{subm[j].label}")
            end
            #-- Only Vertex match
            bestSV_VSMatch[i][j] = (@vertexMatch[rev[i].inVertex.nodeID][subm[j].outVertex.nodeID] + @vertexMatch[rev[i].outVertex.nodeID][subm[j].inVertex.nodeID])/2
            #-- Vertex and SRL
            bestSV_VSMatch[i][j] = bestSV_VSMatch[i][j]/ compareLabels(rev[i], subm[j])
            #-- Only SRL
            #bestSV_VSMatch[i][j] = (double) compareLabels(rev[i].label, subm[j].label);
            flag = 1
            if(bestSV_VSMatch[i][j] > max)
              max = bestSV_VSMatch[i][j]
            end
          end
            
          #for S-V with V-O or V-O with S-V
          if(rev[i].inVertex.type == subm[j].outVertex.type and rev[i].outVertex.type == subm[j].inVertex.type and
            !@vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID].nil? and !@vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID].nil?)
            puts("rev[i].inVertex.name #{rev[i].inVertex.name} && subm[j].inVertex.name #{subm[j].inVertex.name} ::val:: #{@vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID]}")
            puts("rev[i].outVertex.name #{rev[i].outVertex.name} && subm[j].outVertex.name #{subm[j].outVertex.name} ::val:: #{@vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID]}")
            if(!rev[i].label.nil?)
              puts("rev[i].label #{rev[i].label}")
            end
            if(!subm[j].label.nil?)
              puts("subm[j].label #{subm[j].label}")
            end
            #-- Only Vertex match
            bestSV_VSMatch[i][j] = (@vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID] + @vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID])/2
            #-- Vertex and SRL
            #**it is likely that these edges will always have different labels due to the nature and order of comparison of edges
            #S-V edges are likely to be SUBJ while V-O edges could be OBJ and hence different labels are frequent
            #bestSV_VSMatch[i][j] = (double)bestSV_VSMatch[i][j]/ (double)compareLabels(rev[i], subm[j]);
            #-- Only SRL
            #bestSV_VSMatch[i][j] = (double)compareLabels(rev[i].label, subm[j].label);
            flag = 1
            if(bestSV_VSMatch[i][j] > max)
              max = bestSV_VSMatch[i][j]
            end
          end
        end #end of the if condition
      end #end of the for loop for submission edges
        
      if(flag != 0) #if the review edge had any submission edges with which it was matched, since not all S-V edges might have corresponding V-O edges to match with
        puts("**** Best match for:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name} -- #{max}")
        cumEdgeMatch = cumEdgeMatch + max
        count+=1
        max = 0.0 #re-initialize
        flag = 0
      end
    end #end of if condition
  end #end of for loop for review edges
    
  avgMatch = 0.0
  if(count > 0)
    avgMatch = cumEdgeMatch/ count
  end
  puts("Cumulative edge (diff types) match:: #{avgMatch}")
  return avgMatch
end #end of the method   
#------------------------------------------#------------------------------------------

def compareSVOEdges(rev, subm, numRevEdg, numSubEdg)
  puts("***********Inside compare SVO edges numRevEdg:: #{numRevEdg} numSubEdg::#{numSubEdg}")
  bestSVO_SVOEdgesMatch = Array.new(numRevEdg){Array.new}
  cumDoubleEdgeMatch = 0.0
  count = 0
  max = 0.0
  flag = 0
  wnet = WordnetBasedSimilarity.new  
  for i in (0..numRevEdg - 1) #(int i = 0;i < numRevEdg; i++){
    if(!rev[i].nil? and !rev[i+1].nil? and rev[i].inVertex.nodeID != -1 and rev[i].outVertex.nodeID != -1 and rev[i+1].outVertex.nodeID != -1  and rev[i].outVertex == rev[i+1].inVertex)
    #skipping edges with frequent words for vertices
      if(wnet.isFrequentWord(rev[i].inVertex.name) and wnet.isFrequentWord(rev[i].outVertex.name) and wnet.isFrequentWord(rev[i+1].outVertex.name))
        puts("Skipping edge:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name} - #{rev[i+1].outVertex.name}")
        next
      end
        #best match
        for j in (0..numSubEdg - 1) #(int j = 0; j < numSubEdg; j++){
          if(!subm[j].nil? and !subm[j+1].nil? and subm[j].inVertex.nodeID != -1 and subm[j].outVertex.nodeID != -1 and subm[j+1].outVertex.nodeID != -1 and subm[j].outVertex == subm[j+1].inVertex)
            #making sure the types are the same during comparison
            if(rev[i].inVertex.type == subm[j].inVertex.type and rev[i].outVertex.type == subm[j].outVertex.type and rev[i+1].outVertex.type == subm[j+1].outVertex.type and
              !@vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID].nil? and !@vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID].nil? and
              !@vertexMatch[rev[i+1].outVertex.nodeID][subm[j+1].outVertex.nodeID].nil?)
              #System.out.println("rev[i].inVertex.name "+rev[i].inVertex.name +" && subm[j].inVertex.name "+subm[j].inVertex.name+"::val::"+vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID]);
              #System.out.println("rev[i].outVertex.name "+rev[i].outVertex.name +" && subm[j].outVertex.name "+subm[j].outVertex.name+"::val::"+vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID]);
              #System.out.println("rev[i+1].outVertex.name "+rev[i+1].outVertex.name +" && subm[j+1].outVertex.name "+subm[j+1].outVertex.name+"::val::"+vertexMatch[rev[i+1].outVertex.nodeID][subm[j+1].outVertex.nodeID]);
              if(!rev[i].label.nil?)
                puts("rev[i].label #{rev[i].label}")
              end
              if(!subm[j].label.nil?)
                puts("subm[j].label #{subm[j].label}")
              end
              if(!rev[i+1].label.nil?)
                puts("rev[i+1].label #{rev[i+1].label}")
              end
              if(!subm[j+1].label.nil?)
                puts("subm[j+1].label #{subm[j+1].label}")
              end
              
              #-- Only Vertex match
              bestSVO_SVOEdgesMatch[i][j] = (@vertexMatch[rev[i].inVertex.nodeID][subm[j].inVertex.nodeID] +
                  @vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID] + @vertexMatch[rev[i+1].outVertex.nodeID][subm[j+1].outVertex.nodeID])/3
              #-- Vertex and SRL
              bestSVO_SVOEdgesMatch[i][j] = bestSVO_SVOEdgesMatch[i][j]/ compareLabels(rev[i], subm[j])
              bestSVO_SVOEdgesMatch[i][j] = bestSVO_SVOEdgesMatch[i][j]/ compareLabels(rev[i+1], subm[j+1])
              #-- Only SRL
              #bestSVO_SVOEdgesMatch[i][j] = ((double)compareLabels(rev[i].label, subm[j].label) + (double)compareLabels(rev[i+1].label, subm[j+1].label))/(double)2;
              if(bestSVO_SVOEdgesMatch[i][j] > max)
                max = bestSVO_SVOEdgesMatch[i][j]
              end
              flag = 1
           end
          end #end of 'if' condition
        end #end of 'for' loop for 'j'
        
        if(flag != 0) #if the review edge had any submission edges with which it was matched, since not all S-V edges might have corresponding V-O edges to match with
          puts("**** Best match for:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name} - #{rev[i+1].outVertex.name} -- #{max}")
          cumDoubleEdgeMatch = cumDoubleEdgeMatch + max
          count+=1
          max = 0.0 #re-initialize
          flag = 0
        end
      end #end of 'if' condition
    end #end of 'for' loop for 'i'
    
  avgMatch = 0.0
  if(count > 0)
    avgMatch = cumDoubleEdgeMatch/ count
  end
  puts("Cumulative double edge (without syn) match:: #{avgMatch}")
  return avgMatch
end
#------------------------------------------#------------------------------------------

def compareSVODiffSyntax(rev, subm, numRevEdg, numSubEdg)
  puts("***********Inside compare SVO edges with syntax difference numRevEdg:: #{numRevEdg} numSubEdg:: #{numSubEdg}")
  bestSVO_OVSEdgesMatch = Array.new(numRevEdg){ Array.new}
  cumDoubleEdgeMatch = 0.0
  count = 0
  max = 0.0
  flag = 0
  wnet = WordnetBasedSimilarity.new  
  for i in (0..numRevEdg - 1) 
    if(!rev[i].nil? and !rev[i+1].nil? and rev[i].inVertex.nodeID != -1 and rev[i].outVertex.nodeID != -1 and rev[i+1].outVertex.nodeID != -1 and rev[i].outVertex == rev[i+1].inVertex)
      #skipping edges with frequent words for vertices
      if(wnet.isFrequentWord(rev[i].inVertex.name) and wnet.isFrequentWord(rev[i].outVertex.name) and wnet.isFrequentWord(rev[i+1].outVertex.name))
        puts("Skipping edge:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name} - #{rev[i+1].outVertex.name}")
        next
      end
        
      for j in (0..numSubEdg - 1)
        if(!subm[j].nil? and !subm[j+1].nil? and subm[j].inVertex.nodeID != -1 and subm[j].outVertex.nodeID != -1 and subm[j+1].outVertex.nodeID != -1 and subm[j].outVertex == subm[j+1].inVertex)
          #making sure the types are the same during comparison
          if(rev[i].inVertex.type == subm[j+1].outVertex.type and rev[i].outVertex.type == subm[j].outVertex.type and rev[i+1].outVertex.type == subm[j].inVertex.type and
            !@vertexMatch[rev[i].inVertex.nodeID][subm[j+1].outVertex.nodeID].nil? and !@vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID].nil? and
            !@vertexMatch[rev[i+1].outVertex.nodeID][subm[j].inVertex.nodeID].nil?)
            puts("rev[i].inVertex.name #{rev[i].inVertex.name} && subm[j+1].outVertex.name #{subm[j+1].outVertex.name} ::val:: #{@vertexMatch[rev[i].inVertex.nodeID][subm[j+1].outVertex.nodeID]}")
            puts("rev[i].outVertex.name #{rev[i].outVertex.name} && subm[j].outVertex.name #{subm[j].outVertex.name} ::val:: #{@vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID]}")
            puts("rev[i+1].outVertex.name #{rev[i+1].outVertex.name} && subm[j].outVertex.name #{subm[j].inVertex.name} ::val:: #{@vertexMatch[rev[i+1].outVertex.nodeID][subm[j].inVertex.nodeID]}")
            if(!rev[i].label.nil?)
              puts("rev[i].label #{rev[i].label}")
            end
            if(!subm[j].label.nil?)
              puts("subm[j+1].label #{subm[j].label}")
            end
            if(!rev[i+1].label.nil?)
              puts("rev[i+1].label #{rev[i+1].label}")
            end
            if(!subm[j+1].label.nil?)
              puts("subm[j].label #{subm[j+1].label}")
            end
            #comparing s-v-o (from review) with o-v-s (from submission)
            #-- Only Vertex
            bestSVO_OVSEdgesMatch[i][j] = (@vertexMatch[rev[i].inVertex.nodeID][subm[j+1].outVertex.nodeID] +
                @vertexMatch[rev[i].outVertex.nodeID][subm[j].outVertex.nodeID] + @vertexMatch[rev[i+1].outVertex.nodeID][subm[j].inVertex.nodeID])/3
            #-- Vertex and SRL
            #**it is likely that these edges will always have different labels due to the nature and order of comparison of edges
            #bestSVO_OVSEdgesMatch[i][j] = (double) bestSVO_OVSEdgesMatch[i][j]/ (double)compareLabels(rev[i], subm[j+1]);
            #bestSVO_OVSEdgesMatch[i][j] = (double) bestSVO_OVSEdgesMatch[i][j]/ (double)compareLabels(rev[i+1], subm[j]);
            #-- Only SRL
            #bestSVO_OVSEdgesMatch[i][j] = ((double)compareLabels(rev[i].label, subm[j+1].label) + (double)compareLabels(rev[i+1].label, subm[j].label))/(double)2;
            flag = 1
            if(bestSVO_OVSEdgesMatch[i][j] > max)
              max = bestSVO_OVSEdgesMatch[i][j]
            end
          end  
        end #end of 'if' condition
      end #end of 'for' loop for 'j'
      
      if(flag != 0)#if the review edge had any submission edges with which it was matched, since not all S-V edges might have corresponding V-O edges to match with
        puts("**** Best match for:: #{rev[i].inVertex.name} - #{rev[i].outVertex.name} - #{rev[i+1].outVertex.name}-- #{max}")
        cumDoubleEdgeMatch = cumDoubleEdgeMatch + max
        count+=1
        max = 0.0 #re-initialize
        flag = 0
      end
      
    end #end of if condition
  end #end of for loop for 'i'
    
  avgMatch = 0.0
  if(count > 0)
    avgMatch = cumDoubleEdgeMatch/ count
  end
  puts("Cumulative double edge (with syn) match:: #{avgMatch}")
  return avgMatch
end #end of method
#------------------------------------------#------------------------------------------
=begin  
   SR Labels and vertex matches are given equal importance
   * Problem is even if the vertices didn't match, the SRL labels would cause them to have a high similarity.
   * Consider "boy - said" and "chocolate - melted" - these edges have NOMATCH for vertices, but both edges have the same label "SBJ" and would get an EXACT match, 
   * resulting in an avg of 3! This cant be right!
   * We therefore use the labels to only decrease the match value found from vertices, i.e., if the labels were different.
   * Match value will be left as is, if the labels were the same.
=end
def compareLabels(edge1, edge2)
  result = EQUAL
  if(!edge1.label.nil? and !edge2.label .nil?)
    if(edge1.label.equalsIgnoreCase(edge2.label))
      result = EQUAL #divide by 1
    else
      result = DISTINCT #divide by 2
    end
  elsif((!edge1.label.nil? and !edge2.label.nil?) or (edge1.label.nil? and !edge2.label.nil? )) #if only one of the labels was null
      result = DISTINCT
  elsif(edge1.label.nil? and edge2.label.nil?) #if both labels were null!
      result = EQUAL
  end  
  
  return result
end # end of method
end