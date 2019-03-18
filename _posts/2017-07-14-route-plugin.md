---
layout: post
title:  
date:   2017-07-12 16:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- wario
- route
- router

---


之前有一个pcre的插件模板，我们可以基于这个插件模板的代码，构建出多种应用插件，
下面我们就是基于这个模板实现一个，过滤url，发现有特定关键字，就做uri重定向的
插件。

关于LUA PCRE的按装可以参照[LUA PCRE安装(Lrexlib)](https://www.candylab.net/openresty-pcre/)

我们来看一下这种pipeline构成图示：


```
+---------+     +------------------+     +----------+
| src     |     | router-plugin    |     | sink     |
         src - sink               src - sink       ....
+---------+     +------------------+     +----------+
```

插件图示，如下：


```
    +-------------------+
    |  router-plugin    |
   sink                src 
    +-------------------+
```

代码如下：
```lua
local route_plugin = {}

local src = { 
   args="route args"
}

local sink = { 
    name = "route_plugin",
    ver = "0.1"
}

function route_plugin.output(self, list, flg)
    if flg == 0 then return end 
    for k,v in pairs(list) do print(k,v) end 
end


function route_plugin.push(self, stream) 
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end 
end

function route_plugin.init(self)
    self.source = src 
    self.sink = sink
    self.app = require "blues"

    self.app:get("/rule", function(self)
        ngx.log(ngx.ERR, "###[ rule ]###")
    end)
end

function route_plugin.action(self, stream) 
    self.app:run()
end

function route_plugin.match(self, param)
    self.sink['found_flg']=false
    for k,v in pairs(self.source) do
         self.sink[k] = v 
    end 
    self:action(self.sink)
    return self.source, self.sink
end

return route_plugin
```

作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

