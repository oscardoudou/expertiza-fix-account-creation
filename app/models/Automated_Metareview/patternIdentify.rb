require 'Automated_Metareview/wordnetBasedSimilarity'
require 'Automated_Metareview/constants'

class PatternIdentify
=begin
 patterns - an array containing the set of pattern for each class
 numPatterns - an array containing the number of patterns selected for each class.
 numClasses - contains the number of classes under survey
 patternFileName - array containing the names of the pattern files
=end
def getOrderedPatterns(patterns, numPatterns, numClasses, patternFileName)

  wordnet = WordnetBasedSimilarity.new
  classPatterns = patterns
  #COMMENTED FOR FULL-PATTERNS 
  for i in (0..numClasses - 1) #when there are 5 classes in the data
    puts "patterns length:: #{patterns[i].length}"
    classPatterns[i] = compareSingleEdges(classPatterns[i], wordnet, numPatterns[i])
    puts "classPatterns length:: #{classPatterns[i].length}"
  end
      
  #compare patterns from across different classes and eliminate the ones that are semantically similar
  puts("$$$$$$$$$$ Printing the selected edges for each class::")
  #for each class, order the edges and print them
  for i in (0.. numClasses - 1)
    numEdges = classPatterns[i].length #re-setting the number of edges for each class
    printingEdges(classPatterns[i], patternFileName[i])
  end
end
#------------------------------------------#------------------------------------------#------------------------------------------
=begin
  Method in which the edges are compared with each other to determine their semantic values. 
=end

def compareSingleEdges(list, wordnet, numPatterns)
  puts("Inside Compare Edges:: #{numPatterns}")
  edgeMatches = Array.new(numPatterns){Array.new} #a two dimensional matrix containing edges along rows and columns 
  count = 0
  selectPatterns = Array.new
  select_count = 0
  for i in (0..numPatterns - 1) #(int i = 0;i < numEdges; i++){
    if(!list[i].nil?)
      for j in (0..numPatterns - 1) #unidirectional comparison - since the comparisons work in both directions
        if(!list[j].nil?)
          if(i < j)
            edgeMatches[i][j] = compareEdges(list[i], list[j], wordnet)
          end
        end
      end #end of the inner edges loop
      #puts("list[i].averageMatch before:: #{list[i].averageMatch});
      #puts("count before :: #{count});
        
      #calculating average match for edge "i" (with all other edges of the graph)
      count = 0
      puts("Edge-Edge Match::: #{list[i].inVertex.name} - #{list[i].outVertex.name}")
      for j in (0..numPatterns - 1) #(int j = 0; j < numEdges; j++)
        if(!list[j].nil?) #check ensures you dont add garbage values when no edge existed at "j"
          if(i < j and edgeMatches[i][j] != 0.0) #taking average of only the non-zero matches
            print(" - #{edgeMatches[i][j]}")
            list[i].averageMatch = list[i].averageMatch + edgeMatches[i][j]
            count+=1
          elsif(i > j and edgeMatches[j][i] != 0.0) #since edge matching works bi-directional
            print(" - #{edgeMatches[j][i]}")
            list[i].averageMatch = list[i].averageMatch + edgeMatches[j][i]
            count+=1
          end
        end
      end
      puts();
      puts("list[i].averageMatch after:: #{list[i].averageMatch}")
      puts("count after:: #{count}")
        
      if(count == 0)#to avoid a divide by 0 error
        count = 1
      end
         
      list[i].averageMatch = list[i].averageMatch/count
      #selecting only those edges that match others with >= 1 value
      if(list[i].averageMatch >= 1)
        puts("******** Select Edge: #{list[i].inVertex.name} - #{list[i].outVertex.name} is: #{list[i].averageMatch}")
        selectPatterns << list[i]
      end
      puts("******************************************************************************************************")
    end #checking if list[i] is null
  end #end of the outer edges loop    
  #if(list == null)System.out.println("List is null");
  #else System.out.println("List is not null");
  return selectPatterns  
end
#------------------------------------------#------------------------------------------#------------------------------------------

def compareEdges(e1, e2, wordnet)
  #matching in-in and out-out vertices    
  avgMatch_withoutsyntax = wordnet.compareStrings(e1.inVertex, e2.inVertex)
  avgMatch_withoutsyntax = (avgMatch_withoutsyntax + wordnet.compareStrings(e1.outVertex, e2.outVertex))/2
  puts("e1 label:: #{e1.label}")
  puts("e2 label:: #{e2.label}")
  #only for without-syntax comparisons
  avgMatch_withoutsyntax = avgMatch_withoutsyntax/ compareLabels(e1, e2)
  puts("avgMatch_withoutsyntax:: #{avgMatch_withoutsyntax}")
  
  #matching in-out and out-in vertices   
  avgMatch_withsyntax = wordnet.compareStrings(e1.inVertex, e2.outVertex)
  avgMatch_withsyntax = (avgMatch_withsyntax + wordnet.compareStrings(e1.outVertex, e2.inVertex))/2
  puts("avgMatch_withsyntax:: #{avgMatch_withsyntax}")

  puts("**********************************")
  if(avgMatch_withoutsyntax > avgMatch_withsyntax)
    return avgMatch_withoutsyntax
  else
    return avgMatch_withsyntax
  end
end
#------------------------------------------#------------------------------------------#------------------------------------------
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
  if(!edge1.label.nil? and !edge2.label.nil?)
    if(edge1.label.casecmp(edge2.label) == 0)
      result = EQUAL #divide by 1
    else
      result = DISTINCT #divide by 2
    end
  elsif((!edge1.label.nil? and edge2.label.nil?) or (edge1.label.nil? and !edge2.label.nil?))#if only one of the labels was null
    result = DISTINCT
  elsif(edge1.label.nil? and edge2.label.nil?)#if both labels were null!
    result = EQUAL
  end
  return result
end

#------------------------------------------#------------------------------------------#------------------------------------------
=begin
 Writing edge patterns into a file
=end
def printingEdges(edges, patternFileName)  
  #writing the single patterns to a file     
  FasterCSV.open(patternFileName, "w") do |csvWriter|
    for j in (0..edges.length - 1)
      if(!edges[j].nil? and !edges[j].inVertex.nil? and !edges[j].outVertex.nil?)         
        #adding the pattern and match value to the file     
        csvWriter << [(edges[j].inVertex.name.to_s +" - "+edges[j].outVertex.name), edges[j].averageMatch]
      end
    end
  end
end
#------------------------------------------#------------------------------------------#------------------------------------------

end