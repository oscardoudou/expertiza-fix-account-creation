class MergeSort
  
  def sort(list, flag)
    if list.length <= 1
      return list
    end
    middle = list.length/2
    left = Array.new
    right = Array.new
    for i in 0..list.length - 1
      if(i < middle)
        left << list[i]
      else
        right << list[i]
      end
    end
    left = sort(left, flag)
    right = sort(right, flag)
    
    #merge
    return merge(left, right, flag)
  end #end of def sory
  
  def merge(left, right, flag)
    result = Array.new
    while left.length > 0 and right.length > 0 do
      if(flag == 0)# comparing doubles
        if(left[0] >= right[0])
          result << left[0]
          left.delete_at(0)
        else
          result << right[0]
          right.delete_at(0)
        end
      else #flag == 1 -- comparing sentence objects
        if(left[0].avg_similarity >= right[0].avg_similarity)
          result << left[0]
          left.delete_at(0)
        else
          result << right[0]
          right.delete_at(0)
        end
      end
    end
    
    #if left has any elements left
    while left.length > 0 do
      result << left[0]
      left.delete_at(0)
    end  
    
    #if right has any elements
    while right.length > 0 do
      result << right[0]
      right.delete_at(0)
    end 
    return result
  end
  
end

m = MergeSort.new
puts m.sort([1, 7, 4, 3, 0], 0)
