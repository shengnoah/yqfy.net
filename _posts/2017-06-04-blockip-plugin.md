---
layout: post
title: BlockIp插件实现黑名单拦截
date:   2017-06-04 16:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- wario

---
在Pipeline的插件中，有一种插件叫作过滤插件，这种插件的作用是在pipeline流中截获
特定的数据，一旦发现pipeline的流中有这种数据，就根据不同的模式做出相应的处理响
应。

我们来看一下这种pipeline构成图示：


```
+---------+     +---------+     +-------+
| src     |     | filter  |     | sink  |
         src - sink      src - sink     ....
+---------+     +---------+     +-------+
```

在pipeline中有三种插件，排在最前第一个位置的插件就source型的插件，这种插件的特点
是只有输出没有入，至少没有sink端口，在pipeline位置在最左侧，没有上游插件为其提供
数据，如果有数据输入，也来至于pipeline系统提供的数据或是信息。


过滤插件一般都是在pipeline的中段，接收source插件传过来的数据，blockip这个插件的
工作模式就是这样，把http-src这个插件传过来的数据中的ip信息与本地或是特定区域的
block ip列表进行对比，发现流中传递的ip信息在列表内就对应执行相应的拦截动作，或是
出力log信息。


插件图示，如下：


```
    +-----------+
    |  blockip  |
  sink         src 
    +-----------+
```

过滤插件的特点是同时有sink和src，对于blockip这个插件来说，取得当前用户请求的ip
比较简单，http-src插件已经在之前位置把数据放入流中，blcokip取出数据就好，而blockip
表的取得，可以通过blues框架的供的方法，从json文件中或是share diction中取得。

我们在插件内部实现一个常理的Block Ip表，在插件的Action方法中做一简单过滤，代码如下：


```lua
local blockip_plugin = {}

local src = {
   args="blockip args"
}

local sink = {
    name = "blockip_plugin",
    ver = "0.1"
}

local ip_list = {
    '218.30.113.34',
    '127.0.0.1'
}

function blockip_plugin.output(self, list, flg)
    if flg == 0 then return end
    for k,v in pairs(list) do print(k,v) end
end


function blockip_plugin.push(self, stream)
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end
end

function blockip_plugin.init(self)
    self.source = src
    self.sink = sink
    self.ip_list = ip_list
end

function blockip_plugin.action(self, stream)
    for k,v in pairs(self.ip_list) do
        if v == stream.request.ip then
            ngx.exit(404)
        end
    end
end

function blockip_plugin.match(self, param)
    self.sink['found_flg']=false
    for k,v in pairs(self.source) do
         self.sink[k] = v
    end
    self:action(self.sink)
    return self.source, self.sink
end

return blockip_plugin
```

因为是常量Block IP表：

```
local ip_list = {
    '218.123.123.123',
    '127.0.0.1'
}
```

这部分数据可以直接读取json文件读取IP,使用Blues的库。


```lua
function blockip_plugin.action(self, stream)
    for k,v in pairs(self.ip_list) do
        if v == stream.request.ip then
            ngx.exit(404)
        end
    end
end
```

对于屏蔽逻辑，在Action中实现，把当前流中的IP（当前用户请求IP）与Blcok IP表进行
对比，发现在列表中就进行屏蔽。


Blues框架有一个Buffer库，是对Share Diction的简单封装，还有一个BJson的库专门是CSjson
的调用，处理json文件读取。

JSON文件的格式如下：

```lua
[{"Id":74,"RuleType":"blockip","RuleItem":"127.0.0.1"}]
```

我们在init.lua中读取这些数据到Share Diction中：

```lua
local buffer = require "buffer"
local bjson = require "utils.bjson"

local blockip = bjson.loadf("./app/data/rules/blockip.rule", env)
local ip_list = bjson.decode(blockip)
buffer.sett("blockip_list", ip_list)
```

将IP数据从Share Diction读取也是很方便：

```lua
local buffer = require "buffer"
local blockip_list = buffer.gett("blockip_list")
```

我们重写了Action方法，代码如下：

```lua
function blockip_plugin.action(self, stream) 
    local buffer = require "buffer"
    local blockip_list = buffer.gett("blockip_list")

    for k,v in pairs(blockip_list) do
        if v['RuleItem'] == stream.request.ip then
            ngx.say('blockip')
        end 
    end 
end
```

在运行这个插件时，重构的了blues取得nginx数据的lazytable库。


```lua
local lazytable= {

    ngx_request = {
      headers = function()
        return ngx.req.get_headers()
      end,
      cmd_meth = function()
        return ngx.var.request_method
      end,
      rip = function()
        return (ngx.req.get_headers()['X-Real-IP'])
      end,
      cip = function()
        return ngx.var.remote_addr  
      end,
      ip = function()
        return ngx.var.remote_addr  
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

}

local lazy_tbl
lazy_tbl = function(tbl, index)
  return setmetatable(tbl, {
    __index = function(self, key)
      local fn = index[key]
      if fn then
        do  
          local res = fn(self)
          self[key] = res 
          return res 
        end 
      end 
    end 
  })  
end

function lazytable.build_request(self, unlazy) 
        ret = lazy_tbl({}, self.ngx_request)
        for k in pairs(self.ngx_request) do
             local _ = ret[k]
        end
        return ret
end

return lazytable 
```
和之前的代码区是，build_request不是在require时执行的，可以返回lazytable实例后
在调用文件中的执行的，这样保证了时序执行的先后顺序。


而blockip的JSON数据结构，如下：


```
[
{"Id":1,"RuleType":"blockip","RuleItem":"101.226.66.111"},
{"Id":2,"RuleType":"blockip","RuleItem":"116.231.8.230"},
{"Id":3,"RuleType":"blockip","RuleItem":"216.6.111.35"}
]

```

数据会在init阶段加载一次。




作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
