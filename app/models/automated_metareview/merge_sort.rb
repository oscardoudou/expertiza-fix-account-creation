class MergeSort
  def sorting(list, flag)
    #System.out.println("Inside sorting: "+list.size());
    if(list.length <= 1) #if only one element is in the list, return it as it is
      return list
    end
    #implementing sorting as a merge sort algorithm
    middle = list.length/2 #getting the mid value
    left = Array.new
    right = Array.new
    for i in 0..list.length-1
      if(i < middle)
        left << list[i]
      elsif(i >= middle)
        right << list[i]
      end
    end
    
    #sorting left and right arrays  
    left = sorting(left, flag)
    right = sorting(right, flag)
    
    #returning merged list
    return merge(left, right, flag)
  end
  
  def merge(left, right, flag)
    result = Array.new
    while(left.length > 0 or right.length > 0)
      #when both the left and right have elements, compare them
      if(left.length > 0 and right.length > 0)
        if(flag == 0)#for type double. int etc.
          puts "left-right #{left[0]} - #{right[0]}"
          #if the left element is greater than the right element
          if(left[0] >= right[0])
            result << left[0]
            left.delete_at(0) #removing element in the first index
          else
            #System.out.println("Adding:"+right.get(0));
            result << right.get(0)
            right.delete_at(0)
          end
        elsif(flag == 1) #for sentence counter
          #if the left element is greater than the right element
          if(left[0].sent_cover_num > right[0].sent_cover_num) #ordering based on number of sents. covered
            #System.out.println("Adding:"+left.get(0));
            result << left[0]
            left.delete_at(0)
          elsif(left[0].sent_cover_num < right[0].sent_cover_num)
            #System.out.println("Adding:"+right.get(0));
            result << right[0]
            right.delete_at(0)
          #if the cover values are the same, check similarity values
          elsif(left[0].sent_cover_num == right[0].sent_cover_num)
            if(left[0].avg_similarity >= right[0].avg_similarity) #ordering based on number of average similarities
              #System.out.println("Adding:"+left.get(0));
              result << left[0]
              left.delete_at(0)
            else
              #System.out.println("Adding:"+right.get(0));
              result << right[0]
              right.delete_at(0)
            end
          end
        elsif(flag == 2) #for clusters
          if(left[0].avg_similarity >= right[0].avg_similarity) #ordering based on number of average similarities
           #System.out.println("Adding:"+left.get(0));
           result << left[0]
           left.delete_at(0)
          else
           #System.out.println("Adding:"+right.get(0));
           result << right[0]
           right.delete_at(0)
          end
       elsif(flag == 3) #for sentence pairs
          if(left[0].similarity >= right[0].similarity) #ordering based on number of average similarities
            #System.out.println("Adding:"+left.get(0))
            result << left[0]
            left.delete_at(0)
          else
            #System.out.println("Adding:"+right.get(0));
            result << right[0]
            right.delete_at(0)
          end
        end
      #since only the left has elements
      elsif(left.length > 0)
        #System.out.println("Adding:"+left.get(0));
        result << left[0]
        left.delete_at(0)
      #since only the right has elements
      elsif(right.size() > 0)
        #System.out.println("Adding:"+right.get(0));
        result << right[0]
        right.delete_at(0)
      end
    end#end of the while loop
    return result
  end
  
end