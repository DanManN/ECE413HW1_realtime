function [ret,ptr] = parse_varLen(arr, ptr)

    ret = 0;
    while (arr(ptr)>128)
      ret = ret*128 + bitand(arr(ptr),127);
      ptr = ptr+1;
    end
    ret = ret*128 + bitand(arr(ptr),127);

end