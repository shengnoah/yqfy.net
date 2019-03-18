---
layout: post
title:  Wario中实现WAF简单插件
date:   2017-07-27 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- waf-plugin
- wario
- blues
---

对于有的站点来说，除了一些上传文件的场景，基本上都是GET操作比较多，针对一些GET请求中存在的异常数据，可以在pipeline写一个小的WAF插件来拦截。

直接使用了X-WAF的规则文件：


```
[
{"Id":26,"RuleType":"cookie","RuleItem":"\\.\\./"},
{"Id":27,"RuleType":"cookie","RuleItem":"\\:\\$"},
{"Id":28,"RuleType":"cookie","RuleItem":"\\$\\{"},
{"Id":29,"RuleType":"cookie","RuleItem":"select.+(from|limit)"},
{"Id":30,"RuleType":"cookie","RuleItem":"(?:(union(.*?)select))"},
{"Id":31,"RuleType":"cookie","RuleItem":"having|rongjitest"},
{"Id":32,"RuleType":"cookie","RuleItem":"sleep\\((\\s*)(\\d*)(\\s*)\\)"},
{"Id":33,"RuleType":"cookie","RuleItem":"benchmark\\((.*)\\,(.*)\\)"},
{"Id":34,"RuleType":"cookie","RuleItem":"base64_decode\\("},
{"Id":35,"RuleType":"cookie","RuleItem":"(?:from\\W+information_schema\\W)"},
{"Id":36,"RuleType":"cookie","RuleItem":"(?:(?:current_)user|database|schema|connection_id)\\s*\\("},
{"Id":37,"RuleType":"cookie","RuleItem":"(?:etc\\/\\W*passwd)"},
{"Id":38,"RuleType":"cookie","RuleItem":"into(\\s+)+(?:dump|out)file\\s*"},
{"Id":39,"RuleType":"cookie","RuleItem":"group\\s+by.+\\("},
{"Id":40,"RuleType":"cookie","RuleItem":"xwork.MethodAccessor"},
{"Id":41,"RuleType":"cookie","RuleItem":"(?:define|eval|file_get_contents|include|require|require_once|shell_exec|phpinfo|system|passthru|preg_\\w+|execute|echo|print|print_r|var_dump|(fp)open|alert|showmodaldialog)\\("},
{"Id":42,"RuleType":"cookie","RuleItem":"xwork\\.MethodAccessor"},
{"Id":43,"RuleType":"cookie","RuleItem":"(gopher|doc|php|glob|file|phar|zlib|ftp|ldap|dict|ogg|data)\\:\\/"},
{"Id":44,"RuleType":"cookie","RuleItem":"java\\.lang"},
{"Id":45,"RuleType":"cookie","RuleItem":"\\$_(GET|post|cookie|files|session|env|phplib|GLOBALS|SERVER)\\["}
]

```

代码如下：

```lua
local buffer = require "buffer"
local bjson = require "utils.bjson"

local waf_plugin = {}

local src = {
   args="route args"
}

local sink = {
    name = "route_plugin",
    ver = "0.1"
}

function waf_plugin.output(self, list, flg)
    if flg == 0 then return end
    for k,v in pairs(list) do print(k,v) end
end


function waf_plugin.push(self, stream)
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end 
end

function waf_plugin.init(self)
    self.source = src 
    self.sink = sink
end

function waf_plugin.action(self, stream) 
    local rules = bjson.loadf("./data/json/waf_plugin_rule.rule", env) 
    local meta = bjson.decode(rules)

    for k,v in pairs(meta) do
        local rulematch = ngx.re.find
        if rulematch(stream.request.url, v['RuleItem'], "jo") then
            local tpl = require "render"
            ngx.header['Content-Type'] = 'text/html; charset=UTF-8'
            ngx.say(tpl.render("./views/waf.html", {timestamp=ngx.localtime()}))
        end 
    end 
    return self.source,  self.sink  
end

function waf_plugin.match(self, param)
    self.sink['found_flg']=false
    for k,v in pairs(self.source) do
         self.sink[k] = v
    end
    self:action(self.sink)
    return self.source, self.sink
end

return waf_plugin
```


在pipeline上加入这个插件：


```lua
local pipeline = require "wario.pipeline"
local status = pipeline:new {
    require"wario.plugin.content.httpsrc_plugin",
    require"wario.plugin.content.blockip_plugin",
    require"wario.plugin.content.rewrite_plugin",
    require"wario.plugin.content.route_plugin",
    require"wario.plugin.content.waf_plugin",
}
return pipeline
```




作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

