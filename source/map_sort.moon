board = {
  ['0.0.0.1']:1,
  ['0.0.0.5']:5,
  ['0.0.0.3']:3,
  ['0.0.0.2']:2,
  ['0.0.0.9']:9,
  ['0.0.3.3']:3,
  ['0.0.0.6']:6
}


mapsort = (board)->
  b_len = 0
  for k,v in pairs(board)
    b_len = b_len + 1
  
  a1 = {}
  a2 = {}

  i = 0
  for k,v in pairs(board)
    i = i + 1
    a1[i] = k
    a2[i] = v 

  for i = 1, b_len
     max = a2[i]
     for j = i + 1, b_len 
       if a2[j] > max 
         tmp = a2[j]
         a2[j] = max
         a2[i] = tmp
         max = tmp

         tmp1 = a1[j]
         a1[j]  = a1[i]
         a1[i] = tmp1

  ret = {}
  for k,v in ipairs(a1) 
    ret[k] = {a1[k], a2[k]}
  return ret


print("########")

ret = mapsort board

for k,v in ipairs(ret) 
  print(ret[k][1], ret[k][2])


