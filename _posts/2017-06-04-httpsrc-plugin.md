---
layout: post
title: Http-Src插件模板实现介绍
date:   2017-06-04 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- wario

---
在Pipeline的插件中，有一种插件叫做源插件，这种插件的作用就是给pipeline中后续的插
件提供数据。

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

这次我们新建了一个httpsrc的源插件，并重构了插件模板。

图示如下：

```
+-----------+
| http-src  |
           src 
+-----------+
```

代码如下：

```lua
local httpsrc_plugin = {}
local src = { 
   args="httpsrc args"
}

local sink = { 
    name = "httpsrc_plugin",
    ver = "0.1"
}

function httpsrc_plugin.output(self, list, flg)
    if flg == 0 then
        return
    end 

    for k,v in pairs(list) do
        print(k,v)
    end 
end

function httpsrc_plugin.push(self, stream) 
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end 
end

function  httpsrc_plugin.init(self)
    self.source = src
    self.sink = sink
end

function httpsrc_plugin.action(self, stream)
    for k,v in pairs(stream.request) do
       print(k,v)
    end
    self.sink['request']['ip'] = '127.0.0.1'
end

function  httpsrc_plugin.match(self, param)
    self.sink['found_flg']=false
    for kn,kv in pairs(self.source) do
         self.sink[kn] = kv
    end
    self.sink['metadata'] = { data=self.source['data'].." httpsrc add " }
    self:action(self.sink)
    return self.source, self.sink
end

return  httpsrc_plugin

```


http-src源插件的作用是什么呢？用于取得用户请求的数据，url、ip、useragent等数据。
这样在整个pipeline当中，只有http-src取得用户http request的数据，后续的插件原则上
使用的都是http-src向后push数据的复本，除非在某些应用场合下，某插件要修改这些信息
不然，这些数据默认只是只读操作。

理论上这种源插件是没用sink的，但这个版本中的实现是有sink的，这个会在后续重构掉。
我们简单的介绍一个一般的插件模板都有那些接口构成。

push、init、action、match是不可缺少的，因为pipeline调度会回调插件模板里的这些方
法，我们分别看看这几个回调接口。

```lua
function  httpsrc_plugin.init(self)
    self.source = src
    self.sink = sink
end
```

init方法在目前模型中的作用很简单，就是构造自己的caps， src和sink，这两个数据结构
在插件文件中有声明：


```lua
local src = { 
   args="httpsrc args"
}

local sink = { 
    name = "httpsrc_plugin",
    ver = "0.1"
}
```

这就是插件间通信息的协议声明数据，告诉在pipeline中，你前序插件，你可以接受什么样
的数据，告诉后续插件，你能提供数据给后续。因为是一个基础插件没有更复杂的业务数据
所以目前只有name，ver这种信息。

```lua
function httpsrc_plugin.push(self, stream) 
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end 
end
```

push接口的作用，是让pipeline中的数据stream流动起来，pipeline系统就是通过调用这个
方法将数据从一个插件push推送到后面的插件，将前个插件的sink数据给本体的src端，在
插件内部处理完后，又将数据传给自己的sink，返回给pipeline系统，push到下一个插件。

```lua
function  httpsrc_plugin.match(self, param)
    self.sink['found_flg']=false
    for kn,kv in pairs(self.source) do
         self.sink[kn] = kv
    end
    self.sink['metadata'] = { data=self.source['data'].." httpsrc add " }
    self:action(self.sink)
    return self.source, self.sink
end
```

match接口主要作用就是将插件自己的src给自己的sink，回调action方法，而插件主要的业
务代码就是在action中实现的。

```lua
function httpsrc_plugin.action(self, stream)
    for k,v in pairs(stream.request) do
       print(k,v)
    end
    self.sink['request']['ip'] = '127.0.0.1'
end
```

action接口就是插件主要实现自成功能的地方，http-src就是要通过blues框架的方法取得
用户request数据，然后修改了sink，只有这么做，后续插件再读取push过来的数据才可以
取得request信息。action接口的参数就是stream，stream就是self.sink的一个复本，默认
操作这个变量是不会改变sink中的数据的。



```lua
    self.sink['request']['ip'] = '127.0.0.1'
```

注意到这句了， 这是一个代表性的动作，表示http-src插件在实际的修改sink中的内容，
让空数据变成有数据，这里只是用了一个常理代替，而没有去调用blues框架方法取数据设
置，只要给sink['request']设定各种字段，后续pipeline的stream中就有用户http的请求
数据了。


为了年的更清晰一些，我们看看在pipeline中push的数据结构如下 ：


```lua
    local src = { 
        metadata= { 
            data="http data",
            request = { 
                uri="http://www.candylab.net"
            }   
        }   
    }   
```
其中，metadata结构是最主要一个结构数据，她贯串了整个pipeline，设计上是sink和src
只有前后插件间传递，而metadata中的数据是每个插件都接续传递的。

```lua
function httpsrc_plugin.action(self, stream)
    local params = require "nginx"
    self.sink['request']['url'] = params['cmd_url']
    self.sink['request']['ip'] = params['ip']
end
```


那么如何通过Blues的Nginx库来取得用户请求的数据呢，这个httpsrc插件的要完成的主要
任务， 我们把Blues框架的Nginx库和Request库独立出一篇文章介绍: [https://www.candylab.net/blues-nginx-request/](https://www.candylab.net/blues-nginx-request/)


作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
