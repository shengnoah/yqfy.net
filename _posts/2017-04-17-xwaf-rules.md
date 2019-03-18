---
layout: post
title: 模拟WAF一次策略命中
date:   2017-04-17 10:00:18 +0800 
categories: candylab
---


作者：糖果

WAF策略规则的式可以用多种描述形式描述，比如XML、YAML、纯文本、JSON等形式。而我们
这次模拟测试选择的规则的存储形式是JSON：

```lua
[{
  "Id":25,
  "RuleType":"args",
  "RuleItem":"(onmouseover|onerror|onload)\\="
}]
```

这种规则样式来至于XWAF的规则存储形式，在文章的最后我们提供了XWAF的相关信息，追溯
到更早是LoveShell的WAF形式，够成了这条规则的基础数，就是纯“(onmouseover|onerror|onload)\\=”
正则数据来至于loveshell的WAF项目。


完成这次模拟工作，我们需要几个大体的处理过程。

1. 生成规则文件。

2. 读取规则到Openresty的Share.Diction中。

3. 截取用户访问数据。

4. 判断计算用户请求数据是否命中策略。


### 1.生成规则文件。

为了下一步WAF功能的发展， 我们没有直接的用纯XWAF的JSON规则，而是我们在原有的基础上
加入一个新的字段来描述策略，就是Action这个字段，表示的是，策略命中是， WAF应该做出
什么动作。

ruler主要的作用是把文件中的原始转换成新的JSON数据形式，就是加了一个Action。


```lua
[{
  "Id":25,
  "RuleType":"args",
  "RuleItem":"(onmouseover|onerror|onload)\\=",
  "Action":1
}]
```

ruler.lua

```lua
local ruler = {}

function ruler.read(self, var)
    print(var)
    file = io.open(var,"r")
    if file==nil then
        return
    end
    t = {}
    for line in file:lines() do
        table.insert(t,line)
    end
    file:close()
    return(t)
end

function ruler.write(self,var, rule)
    file = io.open(var,"aw")
    if file==nil then
        return
    end

    file:write(rule,"\n")    
    file:close()
    return(t)
end

function ruler.dump(self, in_name, out_name)
    print(name)
    local ret = self:read(in_name)
    rules = {}
    local idx = 0
    for k,v in pairs(ret) do
        idx = idx + 1
        item = {Id=idx, RuleType="args", RuleItem=v, Action=1}
        table.insert(rules,item)
    end
    
    for k,v in pairs(rules) do
         for key,value in pairs(v) do
             print(key, value)
         end
    end 
    self:export(out_name, rules)
end

function ruler.export(self, filename, rule_name)
    local json = require"cjson"
    local ret = json.encode(rule_name)
    self:write(filename, ret)
end

function ruler.loading(self, filename)
    local json = require"cjson"
    local util = require "cjson.util"
    local ret = util.file_load(filename, env)
    local data = json.decode(ret)
    print(util.serialise_value(data))
end


return ruler 

```

测试如何用旧的JSON生成新的JSON。
test.lua

```lua
local ruler = require"ruler"
ruler::export("args.rule", "testcase")
```



### 2.读取规则到Openresty的Share.Diction中。

这部分的内容，我们是先用Blues正常的GET访问，模拟数据的加载，然后再把测试成功的代码
移到Init.lua中，把Content阶段执行的代码，放到Init中。

app.lua

```lua
app:get("/xwaf", function(request,id)
    local json_text = bjson.loadf("./app/data/rules/args.rule", env)
    local t = bjson.decode(json_text)

    buffer.sett("args", t)
    meta = buffer.gett("args")
    ngx.say(bjson.pprint(meta))
end)


app:get("/ltbl", function(request,id)
    local json_text = {Id=25, RuleType="args", RuleItem="(onmouseover|onerror|onload)\\="}
    local t = bjson.decode(json_text)

    buffer.sett("args", t)
    meta = buffer.gett("args")
    ngx.say(bjson.pprint(meta))
end)
```

XWAF有不单一个rules文件，我们选中了其中的args这个文件进行了读取，下面我们要在init.lua中读取这些数据，在init阶段读取，在content阶段的app.lua中读取这个args结构：

init.lua
```lua
local buffer = require "buffer"
local bjson = require "utils.bjson"

local json_text = bjson.loadf("./app/data/rules/testcase", env)
local t = bjson.decode(json_text)
buffer.sett("rule", t)
buffer.set("candylab", "Candylab:Blues")



--这是针对读取args规则的三句新加代码
local json_text = bjson.loadf("./app/data/rules/args.rule", env)
local t = bjson.decode(json_text)
buffer.sett("init_args", t)
```


### 3.截取用户访问数据。

在Init阶段如果我们已经将rule数据加入字典的话，在blues框架只要简单的访问一下字段中的数据就可以。

app.lua
```lua
app:get("/xwaf_rules", function(request,id)
    meta = buffer.gett("init_args")
    ngx.say(bjson.pprint(meta))
end)
```




我们要做数据过滤，而且是基于正则的，所以在项目最开始阶段，直接引入了XWAF的规则文件。在content阶段的读取的这些数据，在init阶段同样可以读取。

而下面的数据碰撞就是针对这个args规则进行演示的,我们继续在content阶段，用一个GET方法请求模拟这个WAF规则命中的过程，不选POST而选GET，因为GET取参数简单，便于集中经历说明规则进行简单的比较，而不是把重点放在解析POST过来的参数和内容上。


```lua
app:get("/greatball", function(request,id)
    meta = buffer.gett("init_args")
    ngx.say(bjson.pprint(meta))
    ngx.say(request.params.cmd_url)
end)
```

### 4.判断计算用户请求数据是否命中策略。

我们创建一个有greatball的请求，我们简单的模拟一些这个请求数据与WAF规则对比的过程。
在这个方法里，我们同时取得了,url和args这个规则所有的数据，下面就是按什么样的方式
进行数据配对了。


下面是代码实现，我们模拟的是在GET请求到的路由处理函数，直接读取规则，然后和用户
提供的请求从比较。

```lua
app:get("/testargs", function(request,id)
    local json_text = bjson.loadf("./app/data/rules/args.rule", env)
    local ret = bjson.decode(json_text)
    for _,rule in pairs(ret) do
        regular = rule["RuleItem"]
        if regular ~= "" and ngx.re.find(request.params.cmd_url, regular, "jo") then
            ngx.say("MATCH!")
        end 
    end 
end)
```


下个实验，我们会把这种策略命中的处理代码，独立成一个单独的功能文件，脱离Blues的路由系统,后 可以直接把这部分过滤用的代码做为Blues自己的安全审计模块，那就是下一篇要介绍的内容。



XWAF是一款开源的WAF产品，详细的介绍大家参考: [开源WEB防火墙XWAF介绍](https://www.openresty.com.cn/X-WAF-README.html) ，作者的官方的站点：[XWAF官网](https://waf.xsec.io/)。


PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
