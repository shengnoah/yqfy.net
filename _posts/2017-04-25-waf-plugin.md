---
layout: post
title: WAF策略规则插件化
date:   2017-04-25 10:00:18 +0800 
categories: candylab
---

作者：糖果

在过去，我们实现了一个最小化的WAF规则分组配对，这种方案的好处就可以集中维护规则，不好的地方
也比较明显，维护改动一次规则，需要影响其它不相关的策略规则，针对这个问题，我们将规则按分类进行
解耦，进行插件化的维护这个策略，一个插件有自己独立的管理的规则。

对于这些插件模块的输入，可以理解为固定的输入，即所有Openresty可以看见的用户请求数据，这样的话，
插件就可以抽像出一些共通的行为与属性，因为Lua没有虚函数和接口的概念，我们直接用table变量和函数
进行简单的模拟。



### 1.上层抽象解耦

从目际构成来看，我们在 app所在目录创建两个子目录:plugin、rules。

在app的根目录创建两个文件:plugin_factory.lua、 plugin_config.lua。


我们按照至顶向下的的方式阶段这些层级文件。



plugin_factory.lua

```lua
local plugin_list = require "plugin_config"

local plugin_factory = {}

function plugin_factory.start(params)
    for k,v in pairs(plugin_list) do
        v:match('params')
    end 
end

return plugin_factory
```

上层的文件设计相对稳定，代码基本不会常变，将插件列表中所有插件循环遍历调用，然后将相对的输入传递给这些插件。

```lua
local factory = require"plugin_factory"
factory.start(params)
```
params中传的数值都是通过Openresty的API进行取得的。


plugin_config.lua

```lua
local xss_plugin = require"plugin.xss_plugin"
local sql_plugin = require"plugin.sql_plugin"
local cc_plugin = require"plugin.cc_plugin"

local plugin_list= { 
    xss=xss_plugin,
    sql=sql_plugin,
    cc=cc_plugin
}

return plugin_list
```

我们通过plugin_config这个封装，模拟接口类的批量生成，所有工作的插件都会在plugin_list里行注册，之后plugin_factory
才会知道这个插件的存在，然后插件的预定的函数会被依次的调用。


### 2.插件接口实现


接下来，我们看一下，一个接口是如何被定义的：

xss_plugin.lua

```lua
local xss_rules = require "rules.xss_rules"
local xss_plugin = {}

function xss_plugin.init(self)
    self.rules=xss_rules
end

function xss_plugin.action(self, param) 
    print("xss_plugin:action")
end

function xss_plugin.match(self, param)
    self:init()
    print("xss_plugin:match")
    for k, v in pairs(self.rules) do
        for _,value in pairs(v) do
            print(value)
           if regular ~= "" and ngx.re.find(params, regular, "jo") then
           end 
        end 
    end 
end

return xss_plugin
```

一个插件内部，规定了三个方法，其中match()这个方法是必须要定义的有，因为上个层级plugin_factory
会统一的调用这个方法。

init()的主要作用是读取rules文件中的数据结构。action()这个函数是比较具体的实现逻辑，你也可以省略
这个函数的实现，直接在match()函数中进行比较，对于一遍的简单逻辑，不分开也可以，对一些比较复杂的
比较插件逻辑，还是解开比较清晰。


最后，看一次rules目录的文件是如何实现的， 拿xss_plugin对应的rules文件为例：


### 3.规则定义

xss_rules.lua

```lua
local urls = { 
    {Id=1, RuleType="url", RuleItem="\.(htaccess|bash_history)", action=1},
    {Id=2, RuleType="url", RuleItem="\.(bak|inc|old|mdb|sql|backup|java|class|tgz|gz|tar|zip)$", action=1},
    {Id=3, RuleType="url", RuleItem="(phpmyadmin|jmx-console|admin-console|jmxinvokerservlet)", action=1},
    {Id=4, RuleType="url", RuleItem="java\.lang", action=1},
    {Id=5, RuleType="url", RuleItem="\.svn\/", action=1},
    {Id=6, RuleType="url", RuleItem="/(attachments|upimg|images|css|uploadfiles|html|uploads|templets|static|template|data|inc|forumdata|upload|includes|cache|avatar)/(\\w+).(php|jsp)", action=1},
}
return urls 
```

这个结构，和之前fileter.lua中提供的rules是子集关系，我们通过这种方式进行解耦。


PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
