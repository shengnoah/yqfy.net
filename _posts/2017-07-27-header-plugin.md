---
layout: post
title:  Wario中实现Header过滤插件
date:   2017-08-02 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- header-plugin
- wario
- blues
---

有时我们需要过滤用户发出的HTTP请求的Header中，是否有我们规定设置的字段，这些字段
的value部分是有要求的， 这个时候Header过滤插件就起作用了， 下面是Header过滤的示意
代码：
 
 
```lua

 
local header_plugin = {}

local src = { 
   args="header args"
}

local sink = { 
    name = "header_plugin",
    ver = "0.1"
}

function header_plugin.output(self, list, flg)
    if flg == 0 then return end 
    for k,v in pairs(list) do print(k,v) end 
end


function header_plugin.push(self, stream) 
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end 
end

function header_plugin.init(self)
    self.source = src 
    self.sink = sink
    self.ip_list = ip_list
end

function header_plugin.action(self, stream) 
    for k,v in pairs(stream.request.headers) do
        ngx.log(ngx.ERR, "###["..k..":"..v.."]###")    
    end 
    if stream.request.headers['key'] then
        ngx.log(ngx.ERR, "###["..stream.request.headers['key'].."]###")
    end 
    
    if not stream.request.headers['key'] then
        local tpl = require "render"
        ngx.header['Content-Type'] = 'text/html; charset=UTF-8'
        ngx.say(tpl.render("waff.html", {timestamp=ngx.localtime()}))
    end 
end

function header_plugin.match(self, param)
    self.sink['found_flg']=false
    for k,v in pairs(self.source) do
         self.sink[k] = v 
    end 
    self:action(self.sink)
    return self.source, self.sink
end

return header_plugin


```


BASIC AUTH就是将加密信息放入header部分，可以在主SERVER和Upstream之间传入一个
key,如果是从主server过来的请求就处理，如果不是就跳转到非业务处理的页面。


作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

