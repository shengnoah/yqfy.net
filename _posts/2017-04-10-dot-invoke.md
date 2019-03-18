---
layout: post
title: Lua中的Self参数
date:   2017-04-10 10:00:18 +0800 
categories: candylab
---


作者：糖果


Lua函数声明中的形参self


Lua中有两种对Table结构的成员函数声明方式：":"和"."。
而对table的函数成员表量的调用也是这两种方试。

允许的：
第一种:用"."声明函数，用":"调用用函数。函数调用时lua会把table变量本身做为第一个参数，传给这个被调用的函数。


第二种:用"."声明函数，用"."调用用函数。再用"."执行table的函数，函数默认不会为这个函数，第一个实参传入self参数。 这里的self不一定要叫self,可以声明为任何的变量名。

```lua
local tbl = {a=1}

function tbl.test(self)
    print("tbl.test")
    print(type(self))
    for k,v in pairs(self) do
        print(k,v)
    end 
end

tbl:test()

function tbl.test1(params)
    print("tbl.test1")
    print(type(params))
    for k,v in pairs(params)do
        print(k,v)
    end 
end

tbl:test1()

```    
上面的代码说明了这个问题：


```lua
local tbl = {a=1}
function tbl.test1(params)
    print("tbl.test1")
    print(type(params))
    for k,v in pairs(params)do
        print(k,v)
    end 
end

tbl.test1()

``` 
上面这段代码，如何用"."声明，"."调用，在函数内部遍历params参数时，就会出错，提示params为空。
   


第三种:用":"声明函数，用":"和"." 两种方式调用函数。 这种情况，无论如何lua也不会把table表量本身作为"self"量传入。

所以，什么时候有"self"存在呢？就是在用"."声明，再后用":"调用。



下面是一个显示程序,总体说明上面提到的问题：


```lua
local tbl = {a=1}

function tbl.test(self)
    print("tbl.test")
    print(type(self))
    for k,v in pairs(self) do
        print(k,v)
    end 
end

tbl:test()

function tbl.test1(params)
    print("tbl.test1")
    print(type(params))
    for k,v in pairs(params)do
        print(k,v)
    end 
end

tbl:test1()
--tbl.test()


print("======================")
for k,v in pairs(tbl) do
    print(k,v)
end
print("======================")


local values = {b=1}

function values:test(self)
    print("value:test")
    print(type(self))
end

values:test()
values.test()


print("======================")
for k,v in pairs(values) do
    print(k,v)
end
print("======================")

```

self这个参数是隐式传入的，参考下面的代码:



```lua
local tbl = {a=1}


function tbl.testMultiParams(params, key)
    print("------------------------")
    print("tbl.testMultiParams")
    print(key)
    print("------------------------")
    for k,v in pairs(params)do
        print(k,v)
    end 
end

tbl:testMultiParams("tstKey")

print("======================")
for k,v in pairs(tbl) do
    print(k,v)
end
print("======================")
```

这就是典型的"."声明,":"调用。

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
