---
layout: post
title:  Openresty中如何实现负载平衡
date:   2017-08-03 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- balancer
- wario
- blues
---


Upstream基本代表就是某主机上某个端口代表的WEB服务，负载均衡就是将相同的WEB服务，部署到
不同主机的不同端口，或是相同的主机的不同端口，根据某个条件让请求，综合根这机器的负载情况，
合理的分配用户的请求，分担所有用户请求都落在一台机器上，造成的阻塞感与相应慢。


有些情况，灰度测试也会根据变理条件，决定让那台upstream就相应用户的请求， 根据用户客户端
传过来的Header中的数据的不同，指定特定服务器为用户服务。


Upstream是需要提前在conf中设定的， 而决定当前请求分配给那个upstream可以使用balancer.set_current_peer
这个函数接口决定。



```lua

    upstream backend {
        server 0.0.0.0;
        balancer_by_lua_block {
            require "wario.balancer"
        }
    }

    server {
        listen 8082;
        location /candylab {
            content_by_lua '
            ngx.say("candylab 8082")
        ';
    }
  }

  server {
        listen 8083;
        location /candylab {
            content_by_lua '
            ngx.say("candylab 8083")
        ';
    }
  }


   server {
        listen 8081;
        location /candylab {
            proxy_pass http://backend;
        }
    }

```

wario.balancer代码决定选择那个upstream,这代码是参考网上朋友的代码改的：


```lua
local port = {8082, 8083}
local backend = ""
local userid = ngx.req.get_uri_args()["userid"] or 0
local hash = (userid % 2) + 1
backend = port[hash]
local ok, err = balancer.set_current_peer("127.0.0.1", backend)
if not ok then
    return ngx.exit(500)
end
```

实际在起调度upstream的主要代码是这部分。
backend在阶段，是没有办法取得Header的数据，使用显示的参数更好一些。





作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

