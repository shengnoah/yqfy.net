---
layout: post
title: WAF分组安全策略匹配
date:   2017-04-17 10:00:18 +0800 
categories: candylab
---

作者：糖果

上次我们做了一个WAF系统策略命中的模拟，这次新实验将要加入更复杂的集团分组策略匹配。简单说就是加入了更多更复杂的策略，为了方便演示，重新组织了策略规则的存储形式，我们用loadstring的方式，加载规则文件。实现的代码，如下：


```lua
local metadata = [[
    local args = {
        {Id=1, RuleType="args", RuleItem="\.\./", action=1},
        {Id=2, RuleType="args", RuleItem="\:\$", action=1},
        {Id=3, RuleType="args", RuleItem="\$\{", action=1},
        {Id=4, RuleType="args", RuleItem="select.+(from|limit)", action=1},
        {Id=5, RuleType="args", RuleItem="(?:(union(.*?)select))", action=1},
        {Id=6, RuleType="args", RuleItem="having|rongjitest", action=1},
        {Id=7, RuleType="args", RuleItem="sleep\((\s*)(\d*)(\s*)\)", action=1},
        {Id=8, RuleType="args", RuleItem="benchmark\((.*)\,(.*)\)", action=1},
        {Id=9, RuleType="args", RuleItem="base64_decode\(", action=1},
        {Id=10, RuleType="args", RuleItem="(?:from\W+information_schema\W)", action=1},
        {Id=11, RuleType="args", RuleItem="(?:(?:current_)user|database|schema|connection_id)\s*\(", action=1},
        {Id=12, RuleType="args", RuleItem="(?:etc\/\W*passwd)", action=1},
        {Id=13, RuleType="args", RuleItem="into(\s+)+(?:dump|out)file\s*", action=1},
        {Id=14, RuleType="args", RuleItem="group\s+by.+\(", action=1},
        {Id=15, RuleType="args", RuleItem="xwork.MethodAccessor", action=1},
        {Id=16, RuleType="args", RuleItem="(?:define|eval|file_get_contents|include|require|require_once|shell_exec|phpinfo|system|passthru|preg_\w+|execute|echo|print|print_r|var_dump|(fp)open|alert|showmodaldialog)\(", action=1},
        {Id=17, RuleType="args", RuleItem="xwork\.MethodAccessor", action=1},
        {Id=18, RuleType="args", RuleItem="(gopher|doc|php|glob|file|phar|zlib|ftp|ldap|dict|ogg|data)\:\/", action=1},
        {Id=19, RuleType="args", RuleItem="java\.lang", action=1},
        {Id=20, RuleType="args", RuleItem="\$_(GET|post|cookie|files|session|env|phplib|GLOBALS|SERVER)\[", action=1},
        {Id=21, RuleType="args", RuleItem="\<(iframe|script|body|img|layer|div|meta|style|base|object|input)", action=1},
        {Id=22, RuleType="args", RuleItem="(onmouseover|onerror|onload)\=", action=1},
    }
    
    local urls = {
        {Id=1, RuleType="url", RuleItem="\.(htaccess|bash_history)", action=1},
        {Id=2, RuleType="url", RuleItem="\.(bak|inc|old|mdb|sql|backup|java|class|tgz|gz|tar|zip)$", action=1},
        {Id=3, RuleType="url", RuleItem="(phpmyadmin|jmx-console|admin-console|jmxinvokerservlet)", action=1},
        {Id=4, RuleType="url", RuleItem="java\.lang", action=1},
        {Id=5, RuleType="url", RuleItem="\.svn\/", action=1},
        {Id=6, RuleType="url", RuleItem="/(attachments|upimg|images|css|uploadfiles|html|uploads|templets|static|template|data|inc|forumdata|upload|includes|cache|avatar)/(\\w+).(php|jsp)", action=1},
    }
    
    local useragent = {
        {Id=1, RuleType="useragent", RuleItem="(HTTrack|harvest|audit|dirbuster|pangolin|nmap|sqln|-scan|hydra|Parser|libwww|BBBike|sqlmap|w3af|owasp|Nikto|fimap|havij|PycURL|zmeu|BabyKrokodil|netsparker|httperf|bench)", action=1},
    }
    
    return {args=args, urls=urls, cookie=cookie, useragent=useragent, post=post}
]]


local script = metadata 
local rules = assert(loadstring(script))()
return rules
```

我们通过最直接的可以被lua认识的语法方式，存储这些策略规则，接下来的任务就是将各种场景下的配对处理抽象成代码模块，数据结构已经定义完了， 看如何对这些数据进行操作。


```lua
local rules = require"meta"

local matcher = {}

function matcher.init(self)
    self.action_id = {"404","500","301"}
    self.match_map = { 
        matcher_group_get = {args=0, urls=0, cookie=0, useragent=0, post=0 },
        matcher_group_post= {args=0, urls=0, cookie=0, useragent=1, post=0 },
        matcher_group_whiteip= {args=0, urls=0, cookie=0, useragent=0, post=0 }
    }   
    
    self.action_seq =  {   
        {id=1, action="start", method = "GET"} ,
        {id=2, action="start", method = "POST"}, 
        {id=3, action="start", method = "WHITEIP"} 
    }   
    
    self.method_id = {GET="matcher_group_get", POST="matcher_group_post", WHITEIP="matcher_group_whiteip"}
end

function matcher.action(self, m_type, param)
    local group_tbl= self.match_map[m_type]
    for k,v in pairs(group_tbl) do
        if v == 1 then
            print(k)
            for key, val in pairs(rules[k]) do
                local regular = val["RuleItem"]
                if regular ~= "" and ngx.re.find(request.params.cmd_url, regular, "jo") then
                    local id = val["action"]
                    print(self.action_id[id])
                end 
            end 
        end 
    end 
end

function matcher.match(self, param)
    matcher:init()
    for k,v in pairs(self.action_seq) do
        local idx = v['method']
        local method = self.method_id[idx]
        matcher:action(method, "param")
    end 
end

matcher:match("param")
```

我们对比一下之前在Blues框架里的模拟处理的代码，如下：

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

经过数据结构模块的分离操作，我们把所有放在文件里的策略，变成了Lua的Table数据结构。然后将可能发生的用户请个场景，与在特定场景下如何进行配对进行了分层Pattern处理。

1. 确认用户当前请求的场景: GET、POST、PUT等。
2. 确人在特点方法下，将用户的请求的数据：URL、URI、参数、Cookie与那些策略进行配对。（args=1, urls=0, cookie=0, useragent=0, post=0 ）[1:与该组策略匹配。 0:不进行匹配]
3. 如果策略命中，进行预先定义好的Action响应操作。（上面的代码以print(self.action_id[id])来表示实行动作）


到此，一个较为复杂的策略命中的判断处理已经实现了， 这模块可以单成一个WAF基础项目，也可以作为框加基本的Filter模块，用于过滤用户请求中的非法数据。

下面的课题是，如何动态的维护和编辑这些策略，是采用命令行的方式，还是采用WEB界面的方式。如何将Action的拦截响应动作，交给Openresty来处理，而这些我们在尝试新的重构变化。





PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
