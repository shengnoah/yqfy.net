---
layout: post
title: PCRE插件替换传统nginx的if判断语句
date:   2017-06-13 16:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- wario
- pcre

---
Openrest的if语名中使用的正侧表达式规范是基于PCRE的，而lua有自己的一套正则规范
我们使用pcre库，可以在lua中延续使用pcre的库。


关于LUA PCRE的按装可以参照[LUA PCRE安装(Lrexlib)](https://www.candylab.net/openresty-pcre/)

我们来看一下这种pipeline构成图示：


```
+---------+     +-------------+     +-------+
| src     |     | pcre-filter |     | sink  |
         src - sink        src - sink     ....
+---------+     +-------------+     +-------+
```

插件图示，如下：


```
    +---------------+
    |  pcre-filter  |
  sink             src 
    +---------------+
```

代码如下：

```lua
pcre = require 'rex_pcre'
ret = pcre.find('127.0.0.1 - testcase\x5Ctester [13/Jun/2017:16:16:42 +0800] "POST /testuri?UserName=tester&UserId=123456789"','UserName=(.*%5C)?(?:tester)(%40.*|@.*|)&UserId=123456789')

```


如果需要针对每条URL进行正则配对，结构如下：

```
rule_tbl = {
    'UserName=(.*%5C)?(?:tester1)(%40.*|@.*|)&UserId=123456789a',
    'UserName=(.*%5C)?(?:tester2)(%40.*|@.*|)&UserId=123456789b',
    'UserName=(.*%5C)?(?:tester3)(%40.*|@.*|)&UserId=123456789c',    
}
```


构造一个URL:

```lua
http://openresty.com.cn/blockip?UserName=user1&UserId=123456789&FillField=
```
 
我们在Pipeline中插入一个新插件，pcre_plugin.lua


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
    ngx.say(stream.request.url)
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
我们在Acton方法中，直接使用PCRE的库rex_pcre：

```lua
function pcre_plugin.action(self, stream) 
    ngx.say(stream.request.url)
    local pcre = require 'rex_pcre'
    local ret = pcre.find(stream.request.url,'UserName=(.*%5C)?(?:user1)(%40.*|@.*|)&UserId=123456789')
    ngx.say(ret)
end
```

而这个插件的目地就是让命中正则的URL可以，继续后续操作。


```lua
local user_list = {
  {'UserName=(.*%5C)?(?:tester1)(%40.*|@.*|)&UserId=123456789a',1},
  {'UserName=(.*%5C)?(?:tester2)(%40.*|@.*|)&UserId=123456789b',2},
  {'UserName=(.*%5C)?(?:tester3)(%40.*|@.*|)&UserId=123456789c',3},
}
```


把规则组织成JSON形式的定义：

```
[{"Id":1,"Response":"user1","RuleItem":"UserName=(.*%5C)?(?:user1)(%40.*|@.*|)&UserId=123456789", "Action":1},
{"Id":2,"RuleType":"user2","RuleItem":"UserName=(.*%5C)?(?:user2)(%40.*|@.*|)&UserId=123456789", "Action":1},
{"Id":3,"RuleType":"user3","RuleItem":"UserName=(.*%5C)?(?:user3)(%40.*|@.*|)&UserId=123456789", "Action":1}]
```


我们将这个文件存到文本文件中，用blues封装的库函数，读取并存到share diciotn中:

```lua
app:get("/data", function(request,id)
    local json_text = bjson.loadf("./app/data/rules/whiteip.rule", env)
    local t = bjson.decode(json_text)

    buffer.sett("r1", t)
    meta = buffer.gett("r1")
    ngx.say(bjson.pprint(meta))
end) 
```
我们把这段逻辑加到插件中：

```lua
function pcre_plugin.action(self, stream)
    ngx.say(stream.request.url)
    local pcre = require 'rex_pcre'
    local ret = pcre.find(stream.request.url,'UserName=(.*%5C)?(?:user1)(%40.*|@.*|)&UserId=123456789')

    local buffer = require "buffer"
    local bjson = require "utils.bjson"

    local json_text = bjson.loadf("./app/data/rules/whiteip.rule", env)
    local t = bjson.decode(json_text)

    buffer.sett("r1", t)
    meta = buffer.gett("r1")
    ngx.say(bjson.pprint(meta))

    for k,v in pairs(meta) do
        ngx.say(v['RuleItem'])
        local ret = pcre.find(stream.request.url,v['RuleItem'])        
        if ret then 
            ngx.say(v['RuleType'])
        end
    end
end
```

其中下面的代码，可以打印出规则的数据结构：


```lua
    local buffer = require "buffer"
    local bjson = require "utils.bjson"

    local json_text = bjson.loadf("./app/data/rules/whiteip.rule", env)
    local t = bjson.decode(json_text)

    buffer.sett("r1", t)
    meta = buffer.gett("r1")
    ngx.say(bjson.pprint(meta))
```


显示出来的数据形式，如下：

```
{
  {
    ["RuleItem"] = "UserName=(.*%5C)?(?:user1)(%40.*|@.*|)&UserId=123456789",
    ["RuleType"] = "user1",
    ["Action"] = 1,
    ["Id"] = 1
  },
  {
    ["RuleItem"] = "UserName=(.*%5C)?(?:user2)(%40.*|@.*|)&UserId=123456789",
    ["RuleType"] = "user2",
    ["Action"] = 1,
    ["Id"] = 2
  },
  {
    ["RuleItem"] = "UserName=(.*%5C)?(?:user3)(%40.*|@.*|)&UserId=123456789",
    ["RuleType"] = "user3",
    ["Action"] = 1,
    ["Id"] = 3
  }
```


我们构造三个URL，用于测试这三个PCRE正侧是否命中：

```
https://openresty.com.cn/blockip?UserName=user1&UserId=123456789&FillField=
https://openresty.com.cn/blockip?UserName=user2&UserId=123456789&FillField=
https://openresty.com.cn/blockip?UserName=user3&UserId=123456789&FillField=
```

我们加入一个简单的判断规则是否命中的逻辑：

```lua
    for k,v in pairs(meta) do
        ngx.say(v['RuleItem'])
        local ret = pcre.find(stream.request.url,v['RuleItem'])
        ngx.say(ret)
        if ret then
            ngx.say(v['RuleType'])
        end
    end
```
如果我们想添加新正则来测试命中URL中的数据，只要修改whiteip.rule这个文件中数据定义：


更新正则的定义，编辑字段如下：    

```
    ["RuleItem"] = "UserName=(.*%5C)?(?:user1)(%40.*|@.*|)&UserId=123456789"
```    
    
符加返回信息体，编辑字段如下：    

```
    ["RuleType"] = "user1"
```    
    
定义响应动作类型, 编辑字段如下：    
   
```
    ["Action"] = 1
```    

当命中后，做什么处理，返回什么数据，自定义处理代码,JSON的定义可以任意定义修改。
一个插件处理一个JSON, 比哪这里把RuleType字段改成Response_Info可能更合适。

我们可以把JSON的定义读取，全部放一个插件中，放在Http-Src的后面，其它用到这些数据
插件的前面，这样更集中，职责简单，便于排错.


--------------------------------------------------------------------------------


下而是复制过来的，PCRE的安装方法：


Lrexlib是PCRE的Lua调用库。在此说一下 Lrexlib的安装过程。


Ubuntu下安装：

1.首先是安装依赖。
```
apt-get install libpcre3
apt-get install libpcre3-dev
```

2.建立连接。
Ubuntu安装的是pcre3，安装完之后系统内才能有libpcre.so的库。
apt-get安装的库文件没有在/usr/lib文件夹下，需要建立连接。

```
ln -s /lib/x86_64-linux-gnu/libpcre.so.3 /usr/lib/libpcre.so
```

3.使用luarocks安装PCRE。
```
sudo luarocks install lrexlib-PCRE PCRE_LIBDIR=/usr/lib/
```

4.测试库。
```
lua -e "require 'rex_pcre'"
```


Centos下安装PCRE：


1.首先是安装依赖。
```
yum install pcre
yum install pcre-devel
```

2.建立连接。
```
ln -s  /usr/lib64/libpcre.so /usr/lib
```

3.使用luarocks安装PCRE。

需要特别说明的地方是，在centos上安装2.8是编译不过的，需要指定2.7.2版本的安装。
```
luarocks install lrexlib-pcre 2.7.2-1 PCRE_LIBDIR=/usr/lib64/
```

4.测试库。
```
lua -e "require 'rex_pcre'"
```

5. PCRE正侧在线解析工具。


[regex101](https://regex101.com/)

[regexpal](http://www.regexpal.com/)



```
Character classes
.	any character except newline
\w \d \s	word, digit, whitespace
\W \D \S	not word, digit, whitespace
[abc]	any of a, b, or c
[^abc]	not a, b, or c
[a-g]	character between a & g
Anchors
^abc$	start / end of the string
\b	word boundary
Escaped characters
\. \* \\	escaped special characters
\t \n \r	tab, linefeed, carriage return
\u00A9	unicode escaped ©
Groups & Lookaround
(abc)	capture group
\1	backreference to group #1
(?:abc)	non-capturing group
(?=abc)	positive lookahead
(?!abc)	negative lookahead
Quantifiers & Alternation
a* a+ a?	0 or more, 1 or more, 0 or 1
a{5} a{2,}	exactly five, two or more
a{1,3}	between one & three
a+? a{2,}?	match as few as possible
ab|cd	match ab or cd
```






作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
