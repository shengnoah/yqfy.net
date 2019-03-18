---
layout: post
title: Blues框架引入Pipeline模式做插件系统
date:   2017-06-21 16:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- pipeline
- blues
---
Blues框架基本是作为Wario项目的一个公共库存在， 代码量很少，我们试着在Blues中也引入
Pipline模式的插件管理系统，这样意着可以控制框架各种功能的开关。

之前的代码比较啰嗦，我们重构了代码：

blues.lua

Blues类，就是过去的Application类，我们把匿名函函数的形参变了， 变成了app数据结结构本身作为参数。

```lua
local Route = require("proute")
local Request = require("request")

local Blues = {}

Blues.blues_id = 1 

function Blues.new(self, lib)
        app.app_id = 1 
        app.router = Route:getInstance()
        app.req = Request:getInstance()

        app.get = function(self, url, callback)
                app:router(url, callback, "GET")
        end 

        app.post = function(self, url, callback)
                app:router(url, callback, "POST")
        end 

        app.run = function(self)
                fun = Route:run(app.router)
                if fun then
                    local ret = fun(app)
                    local rtype = type(ret)
                    if rtype == "table"  then
                        json = require "cjson"
                        ngx.header['Content-Type'] = 'application/json; charset=utf-8'
                        ngx.say(json.encode(ret))
                    end 
                    if rtype == "string"  then
                        ngx.header['Content-Type'] = 'text/plain; charset=UTF-8'
                        ngx.say(ret)
                    end 
                end 
        end 

        return app 
end

return Blues:new {
    pipeline='Pipeline System.'
}


```

Pipeline组件的位置就是代码，如下：

```lua
return Blues:new {
    pipeline='Pipeline System.'
}
```

这就是未来的放插件的位置：


proute.lua

简单路由基上没变动，除了给函数加了self形参。


```lua
local tinsert = table.insert
local req = require "nginx"

local Route =  {}

function Route.getInstance(self)
        local instance = {}
        instance.map = {
            get = {},   --get
            post = {}   --post
        }   

        instance.idea = 1 

        local router = {}
        function router.register(self, app, url, callback, method)
                if method == "GET" then
                    tinsert(self.map.get, {url, callback})
                elseif method == "POST" then
                    tinsert(self.map.post, {url, callback})
                end 
        end 

        router.__call = router.register
        setmetatable(instance, router)
        return instance
end

function Route.run(self, router)

        local url = req.cmd_url
        local method = req.cmd_meth

        if method == "POST" then
                for k,v in pairs(router.map.post) do
                        if router.map.post[k][1] == url then
                                return router.map.post[k][2]
                        end 
                end 
        end 

        if method == "GET" then
                for k,v in pairs(router.map.get) do
                        local match = string.find(url, router.map.get[k][1])
                        --if router.map.get[k][1] == url then
                        if match then
                                return router.map.get[k][2]
                        end
                end
        end

end

return Route
```

然后，把Wario的app.lua里的代码改成最新的形式：


```lua
local app = require "blues"

app:get("/rule", function(self)
    ngx.say(self.app_id)
    self.app_id = 6 
    ngx.say(self.app_id)
end)

return app
```

这样匿名函数可以取得所有加入到app中的库的引用。


```lua
function router.register(self, app, url, callback, method)
    if method == "GET" then
        tinsert(self.map.get, {url, callback})
    elseif method == "POST" then
        tinsert(self.map.post, {url, callback})
    end 
end 
```

router.register()函数的第二个参数，就是调用类Blues的引用，可以通过这个参数，取得所有Blues类的数据，所以
在Route类里不用引入nginx这个库了，在最外层的Blues类中定义这个成员就可以了。
```lua
local req = require "nginx"
```

如果还可以改造的话，就是这样，Blues所有非共通库，都用pipeline组织：


```lua
function Blues.new(self, lib)
end

return Blues:new {
    pipeline='Pipeline System.',
    
    run=function(self) 
        local src = { 
            metadata= { 
                data="http data",
                request = { 
                    uri="http://www.candylab.net"
                }   
            }   
        }   
        for k,v in pairs(self.element_list) do
            v:init()
            v:push(src)
            local src, sink = v:match('params')
            if type(sink) == "table" then
                self:output(sink, 0)
            end 
            src = sink
        end 
    end 

}
```

在new出blues时，以参数传入。可以把 new {} 插号中的位置，当成类声明，直接加入接口与属性数据，这个new出来的
类就是pipeline主类。

不推荐这种写法，看着就乱，独立到文件里更合适，但的确是可以这么写。




作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

