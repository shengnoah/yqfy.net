---
layout: post
title:  在Pipline中使用路由
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

这前我们用blues写的lua代码的时序启点都是从路由出发。我们是在其中某一个路由来创建
一个pipeline，组织起若干个插件来完成某些动作，而这次我们的实验室是，在Openresty的
配置文件中直接创建一个pipeline,然后在pipeline中使用blues的路由来处理相应的路由。

在Openresty China项目中， 我们引入一个Wario的管道应用，然后在一个路由插件中引用
blues的路由。


Openresty China下的一上子站，加入如下配置：

```lua
    access_by_lua '
        local element = require "wario.elements"
        element:run()
    ';  
```


选中几个测试用的插件，最后一个插件就是路由插件，之前有发出来过：

```lua
local pipeline = require "wario.pipeline"
local status = pipeline:new {
    require"wario.plugin.content.httpsrc_plugin",
    require"wario.plugin.content.blockip_plugin",
    require"wario.plugin.content.pcre_plugin",
    require"wario.plugin.content.route_plugin",
}
return pipeline
```

下面就是在插件中，引用路由：

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

如果你的WEB是在nginx上的upstream配置的，一般的WEB系统会有自己的路由规则，而我们可以同时
让用户请求命中upstream的路由之前，先命中Wario路由插件中设定的路由，来做一些你想做的处理
动作,比如对链接进行计数，如果发展有人访问过，把数据存到diction中，有人访问，直接将网页
返回给用户，而不是去mysql中读取，配合路由实现网页的本站缓存，省去了数据库访问。




作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

