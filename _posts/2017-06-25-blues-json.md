---
layout: post
title: 快速解析JSON
date:   2017-06-25 16:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- pipeline
- blues
- wario
---

之前在使用别的语言框架时，发现路由处理json时，引用很多东西，觉得使用起来太啰嗦，
框架改的意思也不大，自己在重写一个小的框架时，就把这种实现简化了。

```lua
    app.json = function(self)
        local jsondata= self.request.params.body
        local t = self.bjson.decode(jsondata)
        return t    
    end 
```

把在匿名函数的调用封装到一个函数里。



```lua
local Blues = {}

Blues.blues_id = 1

function Blues.new(self, lib)

        local app = {}
        app.app_id = 1

        app.bjson = lib.bjson
        app.request = lib.request
        app.router = lib.router
        app.router.req = lib.nginx

        app.get = function(self, url, callback)
            app:router(url, callback, "GET")
        end

        app.post = function(self, url, callback)
            app:router(url, callback, "POST")
        end

        app.run = function(self)
            fun = app.router:finder()
            if fun then
                local content = fun(app)
                app:render(content)
            end 
        end 

        app.json = function(self)
            local jsondata= self.request.params.body
            local t = self.bjson.decode(jsondata)
            return t    
        end 
    
        return app
end

return Blues:new  {
    nginx = require("nginx"),
    bjson = require("utils.bjson"),
    request = require("request"):getInstance(),
    router = require("route"):getInstance()
}

```

Wario在调用时的形参也发生了变化：


```lua
local bjson = require "utils.bjson"
local app = require "blues"

app:get("/json", function(self)
    local ret = self.request.params.body
    local t = bjson.decode(ret)
    return t    
end)

app:get("/getjson", function(self)
    return self:json()
end)

return app 
```



作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

