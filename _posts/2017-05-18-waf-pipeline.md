---
layout: post
title: Openresty基于Pipeline模式的WAF模块构建
date:   2017-05-18 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 

---
一直以来主要考虑点是，不要把代码写乱套了。如何拆分和给组织模块，以什么形式传送数据变成了一个手艺。解耦最直接的方法是分层，先把数据与为业分开，再把业务代码和共通代码分开。数据层对我们系统来说就是规则，系统使用的共通代码都封装到了框架层，而系统功能业务共通的部分，以插件为机能单位分开并建立联系。
数据是面象用户的，框架是面向插件开发者的， 插件的实现就是机能担当要做的事情，不同的插件组合相对便捷的生成新机能，也是插件便利的益处与存在的意义。


![system](https://www.candylab.net/assets/img/projects/wario/pipeline_system_design.png)


## 1.为什么是Pipeline

从宏观的角度讲，设计师设计大楼，是一个构建美好城市的过程。从微观角度讲，工程师码砖盖楼和水泥也是建设国家。之前我们把WAF的过程化编码，通过插件的方式解耦，让系统相对更好的维护和添加新功能，而从设计的角度看，不从实装的细节来说，我们更倾向于用一个更抽象的语言符号系统来描述我们的问题。

现在我们就要用一个被广泛使用的一个比喻，或者说是概念来描述我们的插件：pipeline。

pipeline和stream有着千丝万缕的关系，也用很多的系统使用pipeline来描述软件系统中某些数据和程序处理，可以说pipeline是一个现实中可寻可见的东西， 也可以说是一种设计模式的应用实例化。

简单说吧，这些给Openresty WAF说明使用的Pipeline灵感来源于Graylog流日志处理和Gstreamer的视频流处理类似的Pipeline的概念，如果再有其他雷同，可能就是抄一块去了。


简单来说，基于Openresty的WAF，不考虑效率的问题是话，可以把WAF看成一个大的字符串过滤程序，从Openresty提供的Lua接口和API读取HTTP数据，然后对数据的按照一定的规则进行字符串查找，字符串正则查找。而我们对这个字符串查找程序进行了一次相对更一级的问题抽象：插件化。然而，被归为插件的程序也不是一成不变的，我们就从Pipeline的概念出发，看看可以把Openresty WAF的插件大体分几类，又如何在之后时行更进一步的细化。


## 2.插件分类

流数据与时间有强关联的，比如视频，比如用户操作行为的日志，都是时序相关的。而对一个WEB服务器来说，用户的ＨＴＴＰ请求过程，也分几个阶段。OpenResty就是典型的分出了几个阶段。

在OpenResty社区有一个非常典型的图，来说明这个问题,如下：

![OR](http://ww4.sinaimg.cn/mw690/6d579ff4gw1f3wljbt257j20rx0pa77c.jpg)

在Gstreamer流媒体框架中，除了核心的框架，几乎所有机能都被用各种类型的插件来实现，我们也基于这种考虑，把一些可以被抽出的公通模块以插件为单位来实现，如果你觉这部分的功的代码写的不好，原则上可以自己动手，重构这部分功能的插件。


下面就是一个简单的WAF的实现思路，如果用插件的单位来组强划分，需要用那些插件来构成一个Pipeline， 管道其实就是插件的串或是并行的组合，构成的一个处理流数据的程序组织结构，pipeline是用来组织划分插件程序模块的， 不是组强插件数据的，而数据就是典型的Input。


### 2.1 Pipeline 

一个Pipeline由若干个插件构成，每个插件都有数据插槽src、sink。


### 2.2 Slot

一个插件如果有sink插槽，说明这个插件是可以接受数据入力的，接受其它插件传过来的数据。如果一个插件有src插槽，说明这个插件可以产生出力数据，给其它的插件使用。

关于Pipeline，我们先轻描淡写的说一下，重一点说一下，一个简单的WAF需要那些式样的插件来组合，完成WAF的功能，关键的，这些插件都在OpenResty的那些阶段工作。


事前说一下，share diction算一个共享区域，不算一个可以对接的插件之间的src或是sink数据协议， Slot插槽本身就定义了一个插件输入输出的数据协议，而SC不是，SC是独立于插件的共享区，SC用不好就像全局变理一样，破坏插件间的耦合性。


## 3.插件分类

总体上，我们将插件分成三类：框架插件、业务插件、其它插件。

框架插件：就是驱动业务插件跑起来的，必须有的公通代码。

业务插件：比如XSS、SQL注入这种。

其它插件：没法分类的，没法提取“公约数”的代码。



从童年时期，对两个工作就有一些好奇，一个是木匠、另外一个是烧锅炉的，是相当有技术含量的技术工种，特别是烧锅炉，多危险，烧过了浪费煤，烧少了，不热有人投诉。

随着无声岁月的变化，时代慢慢淡化了木匠这个职业，如果有木匠这一技之长，谁家要是做个窗口凳子什么的，回头不给工钱，说不准，还能送个烧鸡什么的，也不是说非得要点什么，有人送烧鸡也是对木匠这个技术工作的一种认可，技术本应受到人们的重视，现在我们中的很多人都做了程序员， 有人送烧鸡距离我们越来越远，但有时我们又感慨，毕竟程序员是一个改变世界的职业，你们今天被勒索软件勒索了吗，威胁支付比特币了没有？




## 4. 最小化WAF的Pipeline图示


![管道元素](https://www.candylab.net/assets/img/projects/wario/pipeline_elements.png)

我们来看看最小化的Pipeline是什么样的？ 封面上的那个图，其实就是最小化的一个WAF的Pipeline模型。很简单的三个插件，我们来看看这三个插件在Openresty lua执行过程中所处阶段，和这三个的插件应该如何的实现。
之前，我们都是实现一个简易的lua框架来模拟WAF工作的流程， 这简易的框架在WAF构建过程中，主要起的作用请求路由和提供一些封装好的共通函数，这次的方案是使用pipeline插件，我们弱化一下路由，保留使用框架的公通函数，剩下的工作全部由分类的功能插件来完成。

方便其见，之后用字符图示的形式来描述Pipeline，如下图所示：

```
+---------+     +---------+     +-------+
| src     |     | filter  |     | log   |
sink    src - sink      src - sink     ....
+---------+     +---------+     +-------+
```


我们在init阶段，实现一个rulesource插件，用于读取规则。


```lua
local buffer = require "buffer"
local bjson = require "utils.bjson"

local src = { 
    args = bjson.loadf("./app/data/rules/args.rule", env)
}

local sink = nil

local rulesource_plugin = {}

function rulesource_plugin.init(self)
    self.source = src 
    self.sink = sink
    local t = bjson.decode(self.source['args'])
    buffer.sett("rule_args", t)
end

function rulesource_plugin.action(self, param) 
    self:init()
    return self.source,  self.sink
end

function rulesource_plugin.match(self, param)
end

return rulesource_plugin:action("param")
```
从上面的代码可以看出来，
```
local buffer = require "buffer"
local bjson = require "utils.bjson"
```
这两句功能实现是用blues框架完成，不属于WAF的代码， 而其它的代码就是WAF的rulesource插件本身了。


以前我们是通过配置文件，对插件进行初始化的，现在我们用pipeline组织一个新的插件组合，在这之前，我们要重写过去的那些插件，修改一个典型的filter型插件。

```lua
ocal buffer = require "buffer"
local xss_plugin = {}

local src = { 
    args = buffer.get("rule_args")

}
local sink = { 
    name = "xss_plugin"
}


function xss_plugin.push(self, param) 
end

function xss_plugin.init(self)
    self.source = src 
    self.sink = sink
end


function xss_plugin.action(self, param) 
end
function xss_plugin.match(self, param)
    self:init()
    for k, v in pairs(self.rules) do
        for _,value in pairs(v) do
            print(value)
        end 
    end 

    self.sink['found_flg']=true
    return self.source, self.sink
end

return xss_plugin
```

filter型插件是一种最典型的插件，以后的操作与规则分离设计的代码实现也，主要体现在这种插件中。看看过去我们构成和驱动插件工作的代码：

图示如下：

```
+----------+     +-----------+     +-----------+
| xss-plug |     | sql-plug  |     | cc-plug   |
sink      src - sink        src - sink        ....
+----------+     +-----------+     +-----------+
```

代码如下：

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


local plugin_list = require "plugin_config"

local plugin_factory = {}

function plugin_factory:start(params)
    for k,v in pairs(plugin_list) do
        v:match('params')
    end 
end

return plugin_factory:start("params")
```

而现在这种pipeline的形式，与上方法类型，但要以一个pipeline的顺序结构组织插件，然后启动插件运行方法。因为多了src,sink这两个slot，所以加入了push方法在插件之间传递数据。



##  5. 基于pipeline的插件系统与其它的插件系统有什么区别？

在pipeline序列中的插件是可以调换位置的。插件间共享编辑一个metadata和data共享流数据。metadata描述流数据的特征，data数据对插件来说是共享的， 就是通过nginx API获取的HTTP数据，不同的是，传给插件的HTTP Data是一个副本，在Pipeline中的前一个插件，可能会编辑这个数据，后一个数据在读取副本的HTTP Data，可能是在副本的基础上又被变更了。与此同时，每个插件在复到这个副本数据时，会在src或是sink的slot中，加入自己的tag或是私有数据，这数据对下面要进行数据处理的插件，有的是有价值的tag。


到这我们就引入一个问题，pipeline中的插件处理的流数据到底是什么，除了流数据，在src或是sink中还会有什么数据。


- Metadata

- Http Data 

- Plugin Tag


## 6. 插件执行与Nginx阶段的关系


nginx本身把用户请求的处理按阶段进行了划分，可以把这些执行阶段的先后，理解成插件按先后顺序执行，管道中的插件执行在各nginx阶段别分割成若干个子管道。

有的管道只有一个插件，而管道之间的插件是通过share diction来共享规则数据的，因为rule是与特定的处理插件关键的，在执行阶段rule是只读的一般不用更新编辑，而设计上市允许插件对流数据进行编辑的。

而那个插件去读share diction里的那个rule的key是写在插件自己的src和sink中的。

## 3. Pipeline执行与插件模板的回调函数

因为管道中的插件是会被顺序调用的，因此插件模板中的init和action函数也会被正常的回调，而这些回调函数在被调用时，管道系统会把流数据push给单元插件，而接到数据流的插件在接到回调push过来的数据后，进行相应的判断筛选，将编辑后的数据通过sink插槽push给后面的插件，直到管道尾端的插件报警或是记日志，一次管道启动运行的时序就结束了。


我们看一下，一个基于Lua实现的Pipeline插件系统，GST是基于C的单根继承的libc的模拟对象方式来实现pipeline系统，而用Lua简化模式，一些都变的简单了，不变的是类似的系统设计。

图示如下：
```
+------------+
| xss-plugin |
sink        src
+------------+
```
代码如下：
```lua

local xss_plugin = {}

local src = {
   args="xss args"

}
local sink = {
    name = "xss_plugin",
    ver = "0.1"
}


function xss_plugin.push(self, stream)
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
        print(k,v)
    end
end

function xss_plugin.init(self)
    self.source = src 
    self.sink = sink
end

--回调函数，插件的主要处理逻辑在这里，需要的数据通过stream这个参数传入。
function xss_plugin.action(self, stream)
    for k,v in pairs(stream.metadata) do
        print(k,v)
    end
end

function xss_plugin.match(self, param)
    self.sink['found_flg']=false
    for kn,kv in pairs(self.source) do
         self.sink[kn] = kv
    end
    self.sink['metadata'] = { data=self.source['data'] }
    self:action(self.sink)
    return self.source, self.sink
end

return xss_plugin

```


这样设计的结果是，新的机能不是由单个插件来完成的，是把插件组装到管道中来完成的。

我们将http流数据和规则数据分开，然后可以讲管道系统脱离nginx在本地运行，最大限度的移植复用代码。


以上的模板代码，基本上都是固定了，不需要改太多代码，当你拿到这个模板时，如果是Filter类型的插件，只要做几个几个事情：


- 在action回调函数中，读取Pipeline源头插件传过来的metadata， Htttp的数据就在这里。
- 用Blues框架的Buffer库，按插件sink里的name属性的值：xss_plugin， 将属于这个插件的rule数据，读取出来就可以了。
- 如果你原意，可以修改传给下个插件的sink中内容，甚至可以修改其实metadata中的HTTP流数据。




## 7. 如何驱动一个Pipeline运转，并在插件间传递数据。


初期我们不用创建插件工厂，只要把插件当成库require引入即可：

```lua
local xss_plugin = require"plugin.content.xss_plugin"
local sql_plugin = require"plugin.content.sql_plugin"

local plugin_list= { 
    xss=xss_plugin,
    sql=sql_plugin,
}

return plugin_list
```

因为使用lua的原因，我们可以很简单的得到插件的实例。


```lua
local plugin_factory = {}

function plugin_factory:start(params)
    local src = { 
        metadata= { 
            data="http data"
        }   
    }   
    for k,v in pairs(plugin_list) do
        v:init()
        v:push(src)
        src, sink = v:match('params')
        src = sink
    end 
end

return plugin_factory:start("params")
```
通过上面的代码我们模拟了一次pipeline的执行过程，通过基于Pipeline的插件模板编写代码，我们可以快速的构建出很多的插件，并在现阶段进行串行链接，完成特定的任务。不同的插件组成不同的pipeline， 不同的pipeline执行不同的处理。


作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
