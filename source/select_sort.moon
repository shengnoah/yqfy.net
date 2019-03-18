list = {1,5,3,2,9,3,6}
len=#list

for i=1,len 
  max = list[i]
  for j=i+1, len do 
    if list[j]>max then 
      tmp=list[j] 
      list[j]=max
      list[i]=tmp
      max=tmp

--for k,v in ipairs(list)
for item in *list
  print(item)



