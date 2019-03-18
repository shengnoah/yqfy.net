---
layout: post
title:  用路由插件对上游URL进行计数
date:   2017-07-25 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- router
- wario
---

之前我们在pcre_plugin和rewrite_plugin这两个插件时，用json对路由时行配对，现在我们使用
编码形式配对一个路由，并进行计数操作，换成后用模板渲染出来。


 
 
```lua
function route_plugin.init(self)
    self.source = src 
    self.sink = sink
    self.app = require "blues"

    self.app:get("/rule", function(self)
    end)

    self.app:get("/tongji/", function(self)
        local buffer = require"buffer"
        local cnt = buffer.get("t387")       
        local tpl = require "render"
        ngx.header['Content-Type'] = 'text/html; charset=UTF-8'
        ngx.say(tpl.render("./app/wario/views/statics.html", {timestamp=ngx.localtime(), count=cnt}))
    end)                                     

    self.app:get("/topic/387/", function(self)
        local buffer = require"buffer"       
        local cnt = buffer.get("t387")       
        if not cnt then 
           buffer.set("t387", 1)
        else
           cnt = cnt + 1    
           buffer.set("t387", cnt)
        end 
    end)
end


function route_plugin.action(self, stream)
    self.app:run()
end
```

实际上我们在upstream的路由系统福配对到URL之前，先做一遍路由，如果在Lua阶段有路由
命中，我进行访问计数。


然后，我们还可以根据json定义规定要对那些URL进行计数, 修改action中的代码：


```lua
function route_plugin.action(self, stream)
    self.app:run()

    local pcre = require 'rex_pcre'
    local buffer = require "buffer"
    local bjson = require "utils.bjson"

    local json_text = bjson.loadf("./app/wario/data/json/counter.rule", env)
    local t = bjson.decode(json_text)

    buffer.sett("r1_counter", t)
    local meta = buffer.gett("r1_counter")

    for k,v in pairs(meta) do
        local ret = pcre.find(stream.request.url,v['RuleItem'])
        if ret then
            local buffer = require"buffer"
            local cnt = buffer.get(v['RuleType'])
            local new_cnt = 1

            if cnt then
                new_cnt = cnt + 1
            end
            buffer.set(v['RuleType'], new_cnt)
        end
    end
end
```

在action方法中加入了计数功能，下面是原始的规则文件。

```
[
{"Id":1,"RuleType":"t387","RuleItem":"/topic/387/", "Action":1, "uri":"/topic/387/"},
{"Id":2,"RuleType":"t381","RuleItem":"/topic/381/", "Action":1, "uri":"/topic/381/"},
{"Id":3,"RuleType":"t377","RuleItem":"/topic/377/", "Action":1, "uri":"/topic/377/"}
]
```


修改了一下init中tongji那个路由的算法：

```lua
    self.app:get("/tongji/", function(self)
        local pcre = require 'rex_pcre'
        local buffer = require "buffer"
        local bjson = require "utils.bjson"

        local json_text = bjson.loadf("./app/wario/data/json/counter.rule", env)
        local t = bjson.decode(json_text)
        buffer.sett("r1_counter", t)
        local meta = buffer.gett("r1_counter")

        for k,v in pairs(meta) do
            ngx.say(v['RuleType']..":"..tostring(buffer.get(v['RuleType'])))
        end
    end        
```

简单的把所有统计的规则计数都输出遍历。



作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

