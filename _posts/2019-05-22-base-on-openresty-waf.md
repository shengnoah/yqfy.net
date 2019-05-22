---
layout: post
title: 基于Openresty的云WAF工作原理 
date:   2019-05-22 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png

tag:
- openresty 
- Lrexlib
- lua
- pcre

---


## 基于Openresty的云WAF工作原理




### 0×01 概要
随着nginx技术的发展，特别我们国内社区有了Openresty之后，加上了lua扩展的Openresty让原本的nginx越来越强大，基于Openresty的WAF系统百家争鸣，Openresty因为开源低廉的成本，成为构建云WAF的一件利器，但网上很少有整体都基于Openresty的WAF的一个分类说明，以及讲这种基于Nginx的软WAF，到底与硬WAF和基于日志流理分析的WAF有什么区别，所以想用一篇短文来说明科普一下这部分内容。

### 0×02 软WAF与其它WAF之间的关系

![1.png](http://image.3001.net/images/20180420/15242114293847.png)

对于安全运维来说，可能不关心这个HTTP报文是从那里取得的，如论是像硬WAF那种，直接可能从4层或是更底层的位置来解析HTTP报文。或是基于流量分光，把流量复制一份，基于日志统计，判断出威胁，这种就是基于日志分析的WAF，这种WAF最后分析的结果还是要用nginx是去拦截。最后一种就是要说的基于nginx透明代理模式的WAF。暂且我们把WAF分成3种：1.openresty云WAF。2.硬WAF。3.基于日志分析WAF。本文介绍的重点还是基于openresty的云WAF。

### 0×03 Openresty云WAF的扩展分类

![2.png](http://image.3001.net/images/20180420/15242114437321.png)

如果基于openresty或是nginx的WAF，不可避开的就是2种开发方式：

1.C扩展。

2.Lua扩展。

国内目前最受到欢迎的实现方式就是基于lua的nginx扩展，因为lua开发的高效性和扩展性，实现起WAF来如虎添翼。还有就是基于C的扩展实现的Openresty的WA系统。用C实现的WAF要比用lua实现WAF门槛高一些，是因为C相对高的复杂性，基于lua对nginx的api的封装LUA扩展的效果，某些场景也不比基于C的效率低多少。所以用lua开发的效率还是提高明显的情况下，用LUA开发是有明显优势的。

更具体的细分，基于lua的WAF实现也有很多的方式：

基于LUA安全策略
1.基于DSL翻译成LUA：Openresty Edge的商业版WAF就是基于这种，自身创造了一种小语言，可以在由小语言翻译成lua时，优化lua的效率，后期还有自己的正则引擎（非PCRE），这就从低层上，根本性的超越其它软WAF的性能，Edge可是说是一个划时代产品。

2.基于LUA解析JSON策略：OpenWaf，Xwaf，jxwaf这些社区性的WAF，都是基于json描述安全策略解析并执行拦截动作的WAF系统。并对json的生成和编辑做了周边的功有实现，有的还带有一部分的日志智能分析功能。

3.基于LUA解析正则策略：基于纯正则解析的WAF，早期的loveshellWAF就是一种纯正则的WAF系统，采用文件分类策略。

基于C安全策略
基于C扩展的WAF，一个典型的例子就是naxsi这种，用C扩展了nginx或openresty的功能，WAF的策略描述被描述成conf语议的一部分。

1.naxsi：一种基于在conf文件中用新增conf语义来实现安全策略描述的WAF实现方式。

2.swaf：我们内部云实现的一种基于C扩展的WAF。这种WAF可以基于C扩展实现时，再增加LUA扩展来实现定制的安全策略处理，用LUA实现相对复杂的复合性安全策略。

### 0×04 云WAF的规则
对于安装运维人员最关注的就是如果用安全策略描述语言，来实现对HTTP报文的分析与拦截威胁请求。对于分类来说，常见的就是：1.DSL。2.JSON。3.regular。4.conf。

在这里不得不说的，基它基于json正则，还conf配置文件那种，他们都不属于小语言性质的描述，只能说是描述策略用的文件或是描述数据定义。 如果有一个翻译器，把DSL翻译成lua。或是把WAF的lua函数都封装成原子操作，创建一种自定义DSL语义格式，这样安全策略的描述形式更接近于语言，基于小语言的安全策略描述是很灵活的一种实现的，也是很超前的。基于conf的策略描述，和nginx的conf本身的配置有耦合，需要解耦，避免一些定义冲突的问题。

![3.png](http://image.3001.net/images/20180420/15242114944706.png)

### 0×05 透明代理WAF的原理
基于openresty和lua、C扩展的，除非使用mirror镜像模式，基本都是工作在透明代理模式的，这也是这种软WAF的基础工作原理。透明代理的原理就是，让用户的请求，还没传给真实的服务器之前，把流理先给透明代理一份，相当于，把给真实服务器的流量，提前复制一份出来。 我们在真实服务器做处理之前，先把流量中可能存在的威胁过滤一次，过滤的准则是什么呢， 就是安全运维人员，提前写的的那些DSL、json、正则等安全策略描述，让WAF也就是透明代理，安装这些定义去执行过滤分析，然后决定是否拦截当前的请求。

### 0×06 正常行为的请求与响应

![4.png](http://image.3001.net/images/20180420/15242115545695.png)

在正常情况下，用户的原始请求，会通过透明代理，也就是WAF直接传给真实的服务器。服务器响应返回结果给用户，因为在没有命中策略这个前提下，这种请求处理流程就形成了一个请求环路。

![5.png](http://image.3001.net/images/20180420/15242115672821.png)

在这个请求环路上，流量不会被WAF有任何的改动，也没有拒绝的动作，就发给了真实的服务器upstream， 然后upsstream真实服务器把数据返回给用户。

### 0×07 异常行为的请求与响应
异常的流量意味着，用户发出请求的http报文，有命中安全策略规则的一些数据，当规则命中，WAF就开始起作用，没有了第2步由WAF把流量传给真实服务，也不需要第3步，等真实服务器返回请求响应数据给用户，直接跳的第4步，由WAF直接拒绝的请求用户。

![6.png](http://image.3001.net/images/20180420/15242115805034.png)

下面这个图表达的就是拦截的一个关系，当WAF透明代理，发现客户的请求命中的安全策略，就直接拒绝请求返回403，这种处理不好的地方是，攻击者可以意识到有WAF的存在，想办法绕过WAF，进行他想要的操作，那怎么办呢，下面有一个解决方案。

![7.png](http://image.3001.net/images/20180420/15242115946446.png)

### 0×08 蜜罐响应
我们为了不暴露我们的拦截形为，就设计了一个新的处理逻辑，当威胁请求命中安全策略时，我们直接把请求不传给真实的real server，而是把流量给fake upstream或是蜜罐服务器，然后再由蜜罐和攻击者交互，收集攻击的数据，再把流量日志发到大数据分析平台上，准备进行后期分析与自动学习。

![8.png](http://image.3001.net/images/20180420/1524211610361.png)

下面这个图是说，当威胁被WAF发现时，WAF直接把流量给了honeypot，然后由honeypot收集各种payload，然后再把请求的日志写入数据库，类似于clicklhouse这种大数据平台，进入后期分析，我们可以使用SQL或是其它的统计手段，实现检索策略，分析历史存量日志中的问题。透明代理的策略规则，只是针对当前请求的，而日志和payload的保存对于威胁溯源和改善安全策略是很有帮助的，我们还可以通过这些数据，进行自动学习，或是漏报率和误报率的统计，还可以自动生成报告，实时可视化威胁。

![9.png]()

### 0×09 伪代码逻辑

下面这段伪代码就是描述透明代理模式下WAF的工作流程。画图只是一种说明原理的方式，代理则浓缩了整个流程的处理过程。

1.代量模式

```c
http = 用户请求
agetnDeal(http)
```

2.WAF的处理

```c
http agentDeal( http) {
 if (HTTPcontainXSS()) {
 intercept(403)
 }

 if (HTTPContainSQL()) {
 intercept(403)
 }

 if (HTTPContainTrojan()) {
 honeypot(http)
 }

 return realServerDeal(http)
}
```

3.真实服务器的处理

```c
http realServerDeal(http) {
 if (confition1) {
 doSomething()
 }

 if (confition2) {
 doSomething()
 }

 if (confition3) {
 doSomething()
 }
 return http
}
```

4.交给蜜罐处理

```c
http honeypot(http) {
 wrtieLog(http.data)
 return 200
}
```

5.威胁数据写到大数据分析平台

```c
void writeLog(http.data) {
 writeClickHouse(http.data)
}
```

### 0x0A 总结

我们在生产实践中，还是倾向于使用C扩展、LUA扩展和DSL一起来构建WAF系统。C的抽象成度是最底的，开发效率也低，运行效率相对高。LUA的生产性决定了用LUA实现WAF比C实更快（排除个人语言使用熟练成度不同）。DSL是抽象成度最高的一种描述方式，也更贴近人的思维和程序人员惯用的思考模式。基于社区，未来出现的可能还是基于lua和json描述规则策略的软WAF，或是云WAF更多一些。而基于C、LUA、DSL的WAF系统会更强大，构建周期相对长，也更复杂，但正是基于这种强大的工具，让能让安全策略的描述和执行也更强大。

