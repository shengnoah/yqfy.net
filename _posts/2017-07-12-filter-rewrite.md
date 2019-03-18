---
layout: post
title:  URI过滤重定向插件
date:   2017-07-12 16:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- wario
- pcre

---


之前有一个pcre的插件模板，我们可以基于这个插件模板的代码，构建出多种应用插件，
下面我们就是基于这个模板实现一个，过滤url，发现有特定关键字，就做uri重定向的
插件。

关于LUA PCRE的按装可以参照[LUA PCRE安装(Lrexlib)](https://www.candylab.net/openresty-pcre/)

我们来看一下这种pipeline构成图示：


```
+---------+     +------------------+     +----------+
| src     |     | rewriter-filter  |     | sink     |
         src - sink               src - sink       ....
+---------+     +------------------+     +----------+
```

插件图示，如下：


```
    +-------------------+
    |  rewriter-filter  |
   sink                src 
    +-------------------+
```
JSON定义，如下：

```
[
{"Id":2,"RuleType":"candylab","RuleItem":"386", "Action":1, "uri":"/topic/387/"},
{"Id":2,"RuleType":"candylab","RuleItem":"t1opic", "Action":1, "uri":""},
{"Id":3,"RuleType":"candylab","RuleItem":"c1ategory", "Action":1, "uri":""}
]

```

代码如下：


```lua
local pcre_plugin = {}

local src = {
   args="pcre args"
}

local sink = {
    name = "pcre_plugin",
    ver = "0.1"
}

function pcre_plugin.output(self, list, flg)
    if flg == 0 then return end
    for k,v in pairs(list) do print(k,v) end
end


function pcre_plugin.push(self, stream)
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end
end

function pcre_plugin.init(self)
    self.source = src
    self.sink = sink
    self.ip_list = ip_list
end

function pcre_plugin.action(self, stream)
    local pcre = require 'rex_pcre'
    local buffer = require "buffer"
    local bjson = require "utils.bjson"

    local json_text = bjson.loadf("./app/wario/data/json/keyword.rule", env)
    local t = bjson.decode(json_text)

    buffer.sett("r1", t)
    meta = buffer.gett("r1")

    for k,v in pairs(meta) do
        local ret = pcre.find(stream.request.url,v['RuleItem'])
        if ret then
            ngx.req.set_uri(v['uri'], false);
        end
    end

end

function pcre_plugin.match(self, param)
    self.sink['found_flg']=false
    for k,v in pairs(self.source) do
         self.sink[k] = v
    end
    self:action(self.sink)
    return self.source, self.sink
end

return pcre_plugin

```

为了方便演示，没有把规则文件的读取放到init阶段。



作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

