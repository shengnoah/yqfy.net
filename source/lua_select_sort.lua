board = {
['0.0.0.1']=1,
['0.0.0.5']=5,
['0.0.0.3']=3,
['0.0.0.2']=2,
['0.0.0.9']=9,
['0.0.0.3']=3,
['0.0.0.6']=6
}


list = {1,5,3,2,9,3,6} 
len = #list

for i = 1,len do
    max = list[i]
    for j = i+1, len do
        if list[j] > max then
           tmp = list[j]
           list[j] = max
           list[i] = tmp
           max = tmp
        end
	print(list[j])
    end
    print("==========")
end



print("########################")

for k,v in ipairs(list) do
    print(v)
end
