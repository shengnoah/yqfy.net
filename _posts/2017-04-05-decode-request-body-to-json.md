---
layout: post
title: 如何在Openresty中实现一个REST服务
date:   2017-04-06 10:00:18 +0800 
categories: candylab
---
作者：糖果


使用Blues框架在Openresty中实现一个REST服务解析和返回JSON数据，并通过curl向openresty服务器端请求rest，采用GET请求方式，提交一个json,然后路由到对应的匿名函数，通过request.params.body直接取得json数据主体，解析成table变量，放回渲染。
下面：



### 1.接口测试
通过CURL调用我们将要实现的REST接口:

```
curl -X GET  http://0.0.0.0/blues -d  '{"key":"value"}'
```

在app.lua加入如下函数:

### 2.接口实现（案A）

app.lua 
```lua
app:get("/blues", function(request,id)

    --读取用户请求中的body数据
    local ret = request.params.body
    
    --调用cjso库
    local json = require "cjson"
    local util = require "cjson.util"
    
    --对用户请求的数据进入JSON编码， 转成Table变量。
    local t = json.decode(ret)
    
    --递归显示JSON结构中的所有数据。
    ngx.say(util.serialise_value(t))
    
    --返回一个JSON数据结构
    return ret
end)
```

### 3.返回结果

调用结果，如下：
```
{
  ["key"] = "value"
}
{"key":"value"}
```


### 4.接口实现（案B）

下面我们去掉多余的JSON遍历部分，直接将用户请求中的JSON数据转成LUA的Table变量，然后
再把个Table变量，返回为一个JSON进行渲染。

app.lua

```lua
app:get("/blues", function(request,id)
    local ret = request.params.body
    local json = require "cjson"
    local t = json.decode(ret)
    return t
end)
```

### 5.返回结果

调用结果，如下：
```
{"key":"value"}
```

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
