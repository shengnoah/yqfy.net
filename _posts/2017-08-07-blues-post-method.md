---
layout: post
title:  POST处理方法
date:   2017-08-08 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- blues
- post
---

之前Blues的路由简单的都是用于测试GET方法的，激活一下Blues的Post方法，处理Post
匿名函数请求。



便利查找POST匿名函数表的方式和GET的一样，简单粗暴。


```lua
function Route.post(self)
    local url = self.req.cmd_url
    for k,v in pairs(self.map.post) do
        if self.map.post[k][1] == url then
            return self.map.post[k][2]
        end 
    end 
end
```


之前GET路由时序很简单，看一眼就明白了，看一POST函数处理和BLUES里和GET有什么区别：


curl调用

```
curl -X POST www.candylab.net/mypost -d '123'
```

代码在形式上真的和get没啥区别，就看self中关于post的相关的数据取得,代码如下：

```lua
app:post("/mypost", function(self)
    ngx.say("post")
end)
```

然后，我的就要处理如何在nginx.lua中解析post的请求数据。


我们尝试不在框架中解析POST函数，只在匿名函数中直接取得POST请求数据。



ngx.req.read_body()
local req = ngx.req.get_post_args()
ngx.say(req["key"])





作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net




