---
layout: post
title: 最小化LUA WEB框架示意
date:   2016-12-08 17:00:18 +0800 
categories: candylab
---

作者：糖果

WAF不是依据URL为定义中的，而是以规则为中心的。而规则定义了你所关注的数据，默认是
地所有数据进行关注，定义细分的是对他部的数据更关注，WAF关注的不仅仅是URL，下面是
一个传送基于URL的说明程序。

![map_container](https://pic3.zhimg.com/v2-a9679f3d65ce4a5b165d376fb2b92536_b.png)

app.lua
```lua
local Application = require "orc"
app = Application:new()

Application:get("/testcase1", function(request,id)
        print(request["url"])
end)

Application:run()
return app
```

orc.lua
```lua 
local Route = require("route")
local Request = require("request")

local Application = {}

function Application:init(this, req, res)
end

function Application:new()
        local base = {}
        base.id = 1

        function base.init(this, req, res)
                print(base.id)
        end

        local app = {}
        app.id = 123
        app.router = Route:getInstance()
        app.req = Request:getInstance()
        base.__call = base.init
        setmetatable(app, base)
        return app
end

function Application:get(url, callback)
        app.router(url, callback)
end

function Application:doEvent()
        app.router("\default", function()
                print("default")
        end)
        Route:run(app.router)
end

function Application:run()
        fun = Route:run(app.router)
        fun(app.req, app.id)
end

function Application:fin()
end

return Application
```

route.lua
```lua
local tinsert = table.insert
local Route =  {}


function Route:Init()
end

function Route:getInstance()
        local instance = {}
        instance.map = {}
        instance.id = 1

        local base = {}
        function base.register(this, uri, callback)
                tinsert(this.map, {uri, callback})
        end

        base.__call = base.register
        setmetatable(instance, base)
        return instance
end

function Route:run(router)
        local cnt = 1
        for k,v in pairs(router.map) do
                cnt = match()
        end
        return router.map[1][2]
end

function Route:match()
        return true
end

return Route
```

给上面的回调加一个实体形参作参数：


```lua
local Request = {}

function Request:init()
end

function Request:getInstance()

        local name = "request"
        local instance = {
            url="/request",
            getName = function()
                print("CRequest!")
            end
            }

        instance.uri = "candy lab"
        setmetatable(instance, { __index = self,
                                 __call = 
                                        function()
                                            print("Initial Instance")
                                        end
                                 })
        return instance
end

function Request:run()
end

return Request
```

测试内部数据：

```lua
Request = require("request")
req = Request:getInstance()
for k,v in pairs(req) do
        print(k,v)
end
return req
```

通过OpenResty提供的函数，我们的取得用户请求的数据dump到request对象中。


然后，我们修改一上面的调用方法：

app.lua
```lua
local Application = require "orc"
app = Application.new()

for k,v in pairs(app) do
    print(k,v)
end

app:get("/abc", function(request,id)
    print("test abc")
end)

return app.run()
```


orc.lua
```lua
function Application:init(this, req, res)
end

function Application:new()
    local base = {}
    base.id = 1123

    function base.init(this, req, res)
            print("init")
            print(base.id)
    end

    local app = {}
    app.id = 123
    app.router = Route:getInstance()
    app.req = Request:getInstance()
    app.get= function(this, url, callback)
            app:router(this, url, callback)
             end
             
    app.run = function()
                    fun = Route:run(app.router)
                    fun(app.req, app.id)
            end
            
    base.__call = base.init
    setmetatable(app, base)
    return app
end


function Application:get1(url, callback)
    app.router(url, callback)
end

function Application:doEvent()
    print("doEvent")
    app.router("one", function()
            print("test1")
    end)
    app.router("two", function()
            print("test2")
    end)
    app.router("three", function()
            print("test3")
    end)
    Route:run(app.router)
end

function Application:run()
    fun = Route:run(app.router)
    fun(app.req, app.id)
end

function Application:fin()
end

return Application

```

route.lua
```lua
local tinsert = table.insert
local Route =  {}


function Route:Init()
end

function Route:getInstance()
    local instance = {}
    instance.map = {}
    instance.id = 1

    local base = {}
    function base.register(this, baseA, baseB, url, callback)
            tinsert(this.map, {uri, callback})
    end

    base.__call = base.register
    setmetatable(instance, base)
    return instance
end

function Route:run(router)
    for k,v in pairs(router.map) do
    end
    return router.map[1][2]
end

function Route:match()
    return true
end

return Route
```
对于route来讲是遍历路由， 对于WAF来说是遍历策略。进入下一步的改造就是，首先要加
入一个新的参数Param，其次都route进行分类，所谓的分类就是将get、post的路由孙数的
匿名声明，get注册的入get数组，post注册的入post数组。

把之前匿名函数注册到Table的例子翻出来。


```lua
local tinsert = table.insert
map = {
    get = {},
    post = {}
}

function register(uri, callback)
        tinsert(map.get, {uri, callback})
end

register("/one", function() print "one" end)
register("/two", function() print "two" end)
register("/three", function() print "three" end)

uri = "/one"

function run()
    for k,v in pairs(map.get) do
        print(v[1])
        v[2]()
    end
end

run()
```
我们直接修改map数据库，其中区分get和post请求分开，get注册的放到get结构，post同理
当用户的请求来时，判断不同的请求类型，到不同的结构中检索。

在app.lua加入了app:post的新注册调用样式。

```lua
local Application = require "orc"
app = Application.new()

for k,v in pairs(app) do
        print(k,v)
end

app:get("/testcase", function(request,id)
        print("testcase")
end)

app:post("/post", function(request,id)
        print("post")
end)

return app.run()
```

修改orc.lua，添加post注册调用，插入调到区分参数，"get"、“post”。


```lua
local Route = require("route")
local Request = require("request")

local Application = {}

function Application:init(this, req, res)
end

function Application:new()
        local base = {}
        base.id = 1

        function base.init(this, req, res)
        end

        local app = {}
        app.id = 123
        app.router = Route:getInstance()
        app.req = Request:getInstance()
        
        --Get调用就用Get方法注册
        app.get = function(this, url, callback)
            app:router(this, url, callback, "GET")
        end
        
        --Post调用就Post方法注册
        app.post = function(this, url, callback)
            app:router(this, url, callback, "POST")
        end

        app.run = function()
            fun = Route:run(app.router)
            fun(app.req, app.id)
        end
        base.__call = base.init
        setmetatable(app, base)
        return app
end

function Application:get1(url, callback)
        app.router(url, callback)
end

function Application:doEvent()
end

function Application:run()
        fun = Route:run(app.router)
        fun(app.req, app.id)
end

function Application:fin()
end

return Application
```
 
最后修改route.lua，主要改的也是register方法，区分当前的url和函数指针要插入到那个
map的那个存储结构中，另一点就map拆分成两个存储单位。


```lua
local tinsert = table.insert
local Route =  {}


function Route:Init()
end

function Route:getInstance()
        local instance = {}
        instance.map = {
            get = {},   --存储get方法的函数
            post = {}   --存储post方法的函数
        }

        instance.id = 1

        local base = {}
        function base.register(this, baseA, baseB, url, callback, meta)
                --get
                if meta == "GET" then
                        tinsert(this.map.get, {uri, callback})
                elseif meta == "POST" then
                        tinsert(this.map.post, {uri, callback})
                end
        end

        base.__call = base.register
        setmetatable(instance, base)
        return instance
end

function Route:run(router)
        local method = "POST"
        if method == "GET" then
            return router.map.get[1][2]
        elseif method == "POST" then
            return router.map.post[1][2]
        end
end

function Route:match()
        return true
end

return Route
```
这样就将目前的get、post方法区分开了，这种区分可以更多的扩展。接下来，当函数注册
之后，模拟一次用户请求，用户请求的数据有uri、post method等区分，这些数据有一部分
要存储到request对象中，然后根据这些数据,根据url进行匹配,用等号示意匹配。


```lua
function Route:run(router)
        local url = "/def"
        local method = "GET"

        if method == "POST" then
                for k,v in pairs(router.map.post) do
                        print(router.map.post[k][1])
                        print(router.map.post[k][2])
                        if router.map.post[k][1] == url then
                                return router.map.post[k][2]
                        end
                end
        end

        if method == "GET" then
                for k,v in pairs(router.map.get) do
                        print(router.map.get[k][1])
                        print(router.map.get[k][2])
                        if router.map.get[k][1] == url then
                                return router.map.get[k][2]
                        end
                end
        end
end
```

可以单独的把第一组判断都抽出来成为共通，让不同request method的数据操作独立。接下
来我们需要一个view render或是JSON render。


[糖果实验室](https://www.candylab.net)