---
layout: post
title: Blues框架的Nginx与Request库
date:   2017-06-04 11:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- blues
- request
- nginx
- lazy table

---
在说到http-src这个插件时，说过要用blues框架的nginx库来取得用户请求的数据，现在我
们就看看这两个库的的实现的，简要的说明，因为在介绍LazyTable时，专门说了nginx.lua
的实现，而request库是直接调用blues的nginx来取得用户数据，所以我们先看blues的request
是如何使用的,httpsrc插件的使用方法一样。


request库的代码实现很简单，从Blues使用Request库来说明。

在blues框架中创建一个GET匿名方法，用于测试request功能,代码如下：


```lua
app:get("/blockip", function(request,id)
    ngx.say(request.params['cmd_url'])
end)
```

启动Openresty，测试一下这个路由过程：

```
hi start
curl 0.0.0.0/blockip
```

显示结果：
```
/blockip
```


调用时序是：app->request->nginx

匿名函数很简单，我们观察一下request如何让自己的params结构中添充数据的，这数据的
取得就是来至于nginx的lazytable实现，代码如下：


```lua
local params = require "nginx"
local Request = {}

function Request.getInstance()

        local name = "request"
        local instance = { 
                            getName = function() end 
                        }   

        instance.params = params
        setmetatable(instance, { __index = self,
                                 __call = function()
                                        end 
                                 })  
        return instance
end

return Request
```

可能说Request简直就是nginx一层简单的封装，最主要的一句就是：

```lua
instance.params = params
```
就是这句话调用LazyTable实现了数据的初始化，让request.params中有了用户请求数据。

关于nginx.lua库实现不展开说，之前有说明：[使用LazyTable在Openresty中取得用户请求信息](https://www.candylab.net/lazytable-and-request/)

nginx.lua的如何实现不展开，但是目前nginx.lua支持返回那些用户请求数据可查看数据
结构，如下：


```lua
ocal ngx_request = {
  headers = function()
    return ngx.req.get_headers()
  end,
  cmd_meth = function()
    return ngx.var.request_method
  end,
  cmd_url = function()
    return ngx.var.request_uri
  end,
  body = function()
    ngx.req.read_body()
    local data = ngx.req.get_body_data()
    return data
  end,
  content_type = function()
    local content_type = ngx.header['content-type']
    return content_type
  end
}
```

总结，以下：

```lua
params['header']
params['cmd_meth']
params['cmd_url']
params['body']
params['content_type']
```

使用nginx.lua库的例子：

```lua
local params = require "nginx"
url = params['cmd_url']
```

我们直接用引用后，取值即可，在httpsrc插件中也是这么用：


```lua
function httpsrc_plugin.action(self, stream)
    local params = require "nginx"
    self.sink['request']['url'] = params['cmd_url']
end
```


以上就是如何在httpsrc插件中使用blues的nginx.lua库取得用户请求数据。

作者：糖果


PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

