---
layout: post
title: Wario的HTTP请求插件
date:   2017-06-27 13:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- pipeline
- blues
- wario
---


REST-HTTP的这个插件的主要功能就是，将JSON文件中记载的请求数据，通过这个插件，顺序
的发出Request请求。


```lua
local html_plugin = {}

local src = {
   args="HTML ARGS"
}

local sink = {
    name = "HTML_PLUGIN",
    ver = "0.1"
}

function html_plugin.output(self, list, flg)
    if flg == 0 then return end
    for k,v in pairs(list) do print(k,v) end
end


function html_plugin.push(self, stream)
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end
end

function html_plugin.init(self)
    self.source = src
    self.sink = sink
    self.ip_list = ip_list
end


function html_plugin.action(self, stream)

    function requestDeal(req)
        local http = require "resty.http"
        local httpc = http.new()
        local headers = {}

        local res,err = httpc:request_uri(req.uri,{
                            method="GET",
                            body = req.body,
                            headers=req.headers
                        })
        if res then

            if res.status == ngx.HTTP_OK then
                ngx.header['Content-Type'] = 'text/html; charset=UTF-8'
                ngx.say(res.body)
            else
                ngx.exit(res.status)
            end
        end
    end

    local bjson = require "utils.bjson"
    local json_text = bjson.loadf("./app/data/rules/urllist.rule", env)
    local t = bjson.decode(json_text)

    for k,v in pairs(t) do
        requestDeal {
            uri=v.url,
            body=v.body,
            headers=v.headers
        }
    end
end

function html_plugin.match(self, param)
    self.sink['found_flg']=false
    for k,v in pairs(self.source) do
         self.sink[k] = v
    end

    self:action(self.sink)
    return self.source, self.sink
end

return html_plugin
```

```lua
[{"Id":1,"url":"http://lua.ren", "params":"UserName=tester", "headers":{ "User-Agent":"TestAgent"} , "body":"testbody"}]
```


这个插件是一个动作的执行者，还有另一个JSON用来记载更多的行为意义。



请求访问网页：

```lua
op action(1)  result(1) save_name(test_var)
{
    action: {1=请求网页},
    result: {1=存到变量中,2=存到字典中},
    save_name: {var_name}
}
```

比较两个变量结果：

```lua
op action(1) result(1) compare_name(a, b) save_name(var_name3)
{
    action: {1=比较变量， 2=比较字典变量}
    result: {1=存到变量中 2=存到字典中}
    compare_name: {var_name1, var_name2}
    save_name: {var_name3}
}
```


实际上我们相通过对以上命令的支持，来做一些自动化操作。 继续使用插件的方式的形式
解析Action动作描述的形为，实现慢速请求。


RESTY-HTTP除了request_uri外，还有request、request_proxy、request_pipline的请求方式。
request_proxy其实内部调用的还request， 而reqeuest_uri是request的一种封装的常
链接方案。


```lua

app:get("/topic/383/", function(self)
    local http = require "resty.http"
    local httpc = http.new()
    httpc:set_timeout(1000)
    local ok, err = httpc:connect("127.0.0.1",80)

    if not ok then
      ngx.say(ngx.ERR, err)
      return
    end

    local req = {
                    path="/topic/383/",
                    method="GET",
                    body = "",
                    headers={}
                }

    local res, err = httpc:proxy_response(httpc:proxy_request(req))
    httpc:set_keepalive()
    if res then
        if res.status == ngx.HTTP_OK then
            ngx.header['Content-Type'] = 'text/html; charset=UTF-8'
            ngx.say(res.body)
        else
            ngx.exit(res.status)
        end
    end

end)
```    

request_proxy可把用户当前请求转给connect(host,post)的服务器，uri就是录前请求的uri。

下而request_proxy的源代码：

```lua
function _M.proxy_request(self, chunksize)
    return self:request{
        method = ngx_req_get_method(),
        path = ngx_re_gsub(ngx_var.uri, "\\s", "%20", "jo") .. ngx_var.is_args .. (ngx_var.query_string or ""),
        body = self:get_client_body_reader(chunksize),
        headers = ngx_req_get_headers(),
    }
end
```

实际效果就是，下游请求发过来啥，就转发给过去啥。

而request调用的就是内部的send_request方法：

```lua
function _M.request(self, params)
    params = tbl_copy(params)  -- Take by value
    local res, err = self:send_request(params)
    if not res then
        return res, err
    else
        return self:read_response(params)
    end
end
```

reqeust_uri没有直接调用send_request，是自己实现了一个长链接，然后调用了request
调用关系时。

request->send_request->send_body

request_uri->request->send_request->send_body


request_uri其实就是对request的封装，函数形参多了一个URI的参数，而request_uri函数内
就解析URI，开起长链接然后再调用request函数，后面的调用时序就request函数的调用时序。

我们，看一下request_uri的代码：


```lua
function _M.request_uri(self, uri, params)
    params = tbl_copy(params or {})  -- Take by value

    local parsed_uri, err = self:parse_uri(uri, false)
    if not parsed_uri then
        return nil, err
    end

    local scheme, host, port, path, query = unpack(parsed_uri)
    if not params.path then params.path = path end
    if not params.query then params.query = query end

    local c, err = self:connect(host, port)
    if not c then
        return nil, err
    end

    if scheme == "https" then
        local verify = true
        if params.ssl_verify == false then
            verify = false
        end
        local ok, err = self:ssl_handshake(nil, host, verify)
        if not ok then
            return nil, err
        end
    end

    local res, err = self:request(params)
    if not res then
        return nil, err
    end

    local body, err = res:read_body()
    if not body then
        return nil, err
    end

    res.body = body

    local ok, err = self:set_keepalive()
    if not ok then
        ngx_log(ngx_ERR, err)
    end

    return res, nil
end

```

request_uri、proxy_request都是封装调用request。

request_uri调用前传入request前，解析了用户传入的URI，转成了param参数给request。

proxy_request是调用转发请求的参数，比如URI的信息来自于ngx_var.uri，A访问C，但
经过了B，B把A的请求参数取得，调用request请求发给C。



RESTY-HTTP底层用的就是ngx.socket.tcp，网上找一段例子：



```lua
local sock = ngx.socket.tcp()
local ok,err = sock:connect('lua.ren',80)

if not ok then
    ngx.say('Failed to connect whois server',err)
    return
end

sock:settimeout(5000)
local ok, err = sock:send("www.candylab.net")
if not ok then
    ngx.say('Failed to send data to whois server', err)
    return
end

local line, err, partial = sock:receive('*a')
if not line then
    ngx.say('Failed to read a line', err)
    return
end

ngx.print(line)
```

RESTY-HTTP和上面的程序相比，构建了更封复杂的请求体，并对目标服务返回的数据有
列完善的解析。

代码中，有一处把用户的request请求体输出到日志中：


```lua
function _M.send_request(self, params)
    local req = _format_request(params)
    ngx_log(ngx_ERR, "\n", req)
    local bytes, err = sock:send(req)
end

```


上面的代码，只是其中的一段，把ngx_DEBUG改成了ngx_ERR，这样在err日志中就可以看到
每次请求的请求体， 所有的原始数据都是由用户提供的。request数据需要_format_request
进行整型。


在sock:send(req)之后的主要任务就是处理response数据，可以简化一下RESTY-HTTP的实现。
搞一个散装版的实现方案，思想都是一样，如果不是传输HTTP协议，传别的协议的数据也一样。


POST有多数据提交，reponse也有大数据块接受：

与HTTP类似的协议，STOMP也是明文的数据协议：


```lua

    local client = require "stomp"
    local mq, err = client:new()
    local ok, err = mq:connect("127.0.0.1", 61613)
    local msg = "say hi!"
    local headers = {}
    headers["destination"] = "/queue/test"
    headers["app-id"] = "APP"
    local ok, err = mq:send(msg, headers)

```
 
 除了数据主体msg，其它的数据定义完部都定义在header中，destination和app-id都是
 STOMP协议本身数据定义， HOST和PORT也是在一起标记rabbitMQ的主机与端口。
 
 
```python
import stomp
import time
import sys
import random
import json

class MyListener(stomp.ConnectionListener):
    def on_error(self, headers, message):
        print('received an error %s' % message)

    def on_message(self, headers, message):
        for k,v in headers.iteritems():
            print('header: key %s , value %s' %(k,v))
        print('received message\n %s'% message)

conn = stomp.Connection([('127.0.0.1',61613)])
conn.set_listener('somename',MyListener())
conn.start()
conn.connect(wait=True)

message = 'say hi!'
dest = '/queue/test'
headers = {
            'seltype':'mandi-age-to-man',
            'type':'textMessage',
            'MessageNumber':random.randint(0,65535)
          }

metadata = []
info_json = json.dumps(metadata)
conn.send(body=info_json, destination='/queue/test')
conn.disconnect()
```

上面是一个python版的STOMP程序，用set_listener定义一个回调，然后发送一个消息给队列
然后on_message就会收到对应的消息和headers数据，然后列出STOMP几个请求的数据帧格式。


```lua
connect_frame = {
  "CONNECT\n",
  "accept-version:1.2\n",
  "login:guest\n",
  "passcode:guest\n",
  "host:/\n",
  "\n\n",
  "\0"
}

send_frame = {
  "SEND\n",
  "destination:/queue/test\n",
  "app-id:APP\n",
  "\n",
  "say hi!\n",
  "\0"
}

包体的第一个字段“CONNECT,SEND”都是协议的命令，剩下的是说明字段。
```
 
``` 
GET /puku/pic/2017-06-26/8328.html HTTP/1.1
Content-Length: 0
User-Agent: Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36
Host: www.mumujita.com
```

```lua

app:get("/sock", function(self)
    local sock = ngx.socket.tcp()
    local ok,err = sock:connect('wwww.openresty.com.cn',80)
    if not ok then
        ngx.say('Failed to connect whois server',err)
        return
    end

    local s1='GET / HTTP/1.1\r\n\r\n'
    locaol s2='\r\n'
    sock:settimeout(5000)

    local http_data=s1..s2
    local ok, err = sock:send(http_data)
    if not ok then
        ngx.say('Failed to send data to whois server', err)
        return
    end

    local line, err, partial = sock:receive('*a')
    if not line then
        ngx.say('Failed to read a line', err)
        return
    end

    ngx.print(line or partial)
end)
```

HTTP协议也是基于TCP发送名文字符串，因为HTTP是名文协议，实际上就是按协议格式传字符串。

从模式上讲，有两种情况需要使用循环处理，一种发送时数据包大，需要分块发送，另一种是因为
返回包很大，需要在status状态是关闭之前，接收所有数据。


请求体
```
GET /candylab.htm HTTP/1.1
Accept: */*
Accept-Language: zh-cn
Accept-Encoding: gzip, deflate
If-Modified-Since: Wed, 17 Oct 2007 02:15:55 GMT
If-None-Match: W/"158-1192587355000"
User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)
Host: 192.168.2.162:8080
Connection: Keep-Alive
```

简单说，类似的这种库就是用socket进行字符串传送，如果针对http协议来说，总体上就两
部分，处理request和reponse两部分的逻辑，程序都是自己特定数据的处理，有自己期待输
入数据和特定的程序响应结果，数据是和业务直接相关的， 而数据是有边界的，如果给程序
提供了一种，程序没有考虑到非正常业务数据，就可以造成出问题，程序处理不了所有的
数据，但可以确定只处理什么数据，有一情况程序也超出了自己控制，就是程序本身出现了
bug，不显然不是程序作者的预期，如果有一程序，可以把其它程序的所有非法数据都过滤
掉，是否就没有安全隐患了呢？就算有这种程序，这种程序也不会所有人都用，而这种程序
本身也是人写的程序，也是有逻辑边界和数据边界的。





作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net


