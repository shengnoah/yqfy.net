---
layout: post
title: Blues路由时序重构
date:   2017-06-21 16:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- pipeline
- blues
- wario
---


发现Router的写法有一个多余的地方，就是用self参数，又另外传入自身，这样做很不合理。

```lua
local tinsert = table.insert

local Route =  {
    map = {
        get = {},
        post = {}
    }
}

function Route.register(self, app, url, callback, method)
        if method == "GET" then
            tinsert(self.map.get, {url, callback})
        elseif method == "POST" then
            tinsert(self.map.post, {url, callback})
        end
end


function Route.getInstance(self)
        local instance = {}
        instance.__call = self.register
        setmetatable(self, instance)
        return Route
end

function Route.get(self)
    local url = self.req.cmd_url
    local map = self.map.get
    for k,v in pairs(map) do
        local ret = self:match(url, map[k][1])
        if ret then
            return map[k][2]
        end
    end
end


function Route.post(self)
    for k,v in pairs(self.map.post) do
        if self.map.post[k][1] == url then
            return self.map.post[k][2]
        end
    end
end

function Route.finder(self)
    local method = self.req.cmd_meth

    local ftbl = {
        GET=self.get,
        POST=self.post
    }

    local ret = ftbl[method](self)
    return ret
end

function Route.match(self, src, dst)
    local ret = string.find(src, dst)
    return ret
end

return Route
```


并且，这前blues.lua的require显的很乱，也重新写了：

```lua
local Blues = {}

Blues.blues_id = 1 

function Blues.new(self, lib)

        local app = {}
        app.app_id = 1 

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

        app.render= function(self, content)
            local rtype = type(content)
            if rtype == "table"  then
                 json = require "cjson"
                 ngx.header['Content-Type'] = 'application/json; charset=utf-8'
                 ngx.say(json.encode(content))
            end
            if rtype == "string"  then
                ngx.header['Content-Type'] = 'text/plain; charset=UTF-8'
                ngx.say(content)
            end
        end

        return app
end


return Blues:new  {
    nginx = require("nginx"),
    request = require("request"):getInstance(),
    router = require("route"):getInstance()
}
```

Wario在调用时的形参也发生了变化：


```lua
local bjson = require "utils.bjson"
local app = require "blues"


app:get("/blues", function(self)
    self.app_id = 6 
end)

app:get("/json", function(self)
    local ret = self.request.params.body
    local t = bjson.decode(ret)
    return t    
end)

return app 
```



作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

