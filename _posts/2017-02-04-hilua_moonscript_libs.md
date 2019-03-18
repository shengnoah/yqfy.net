---
layout: post
title: LUA的WEB框架与MoonScript库
date:   2017-02-04 11:00:18 +0800 
categories: candylab
---


作者：糖果


上一篇是用.so作为框架的库，这是接上回，用MoonScript实现库。


在HiLua工程中，创建/libs/moon目录，建立MoonScript库代码，如下：

HiLog.moon

```lua
class HiLog
    @log: =>
        print("HiLog...")
        return "HiLog..."
```

HiLog.lua

```lua
local HiLog
do
  local _class_0
  local _base_0 = { } 
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "HiLog"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end 
  })  
  _base_0.__class = _class_0
  local self = _class_0
  self.log = function(self)
    print("HiLog...")
    return "HiLog..."
  end 
  HiLog = _class_0
  return _class_0
end

```

创建新工程与app:

```shell
hi project Test-HiLua
hi app Test-HiLua
```

修改一下app.lua

```lua
require "log"
local HiLog = require "HiLog"
local Application = require "orc"
app = Application.new()

app:get("/hilua", function(request,id)
    ret = HiLog:log()   
    ngx.say(ret)
    ngx.say('hilua') 
end)

return app.run()
```



库可以用C写生成SO共享库，也可以用MoonScript翻译成Lua，然后与框架路由结合起
来，这种依赖就是纯调用依赖关联，尽量不产生数据关联。







<a href="https://github.com/shengnoah/hilua/tree/libs/libs/moon" target="_blank">源码地址：</a>

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

