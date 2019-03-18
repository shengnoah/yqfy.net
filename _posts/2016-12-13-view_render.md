---
layout: post
title: Lua Web的View Render的实现
date:   2016-12-13 17:00:18 +0800 
categories: candylab
---


一般像Django这种python的WEB框架，都有一个单独的对象类来处理Html渲染,HttpResponse。
Lua同样可以实现一个单独的类，完成类似的工作。一起完成整个渲染过程，有两个类共同来
完成，一个是Response,另一个是Tempalte。Tempalte用于处理将HTML文档从文件中读取出来
进行格式化整形，整形后的数据交给Render类来处理，Render除了处理渲染HTML，还可以用
于渲染JSON，最后渲染HTML的OpenResty API其实可以是ngx.say，将文本输出到浏览器上。
可以说Response就是对Template的封装调用。

或者不使用response类，直接返回字符串或是table数据类型， 判断如果返回的类型是字符
串，直接当成HTML渲染，如果返回是Table类型的数据，当成JSON数据渲染。


response.lua
```lua
local Template = require("template")                                                                                                                                                                                                             
local Response = {}                                                                                                                                                                                                                          

function Response:render(style, file, param)                                                                                                                                                                                                     
    Template:render("/index.html", "list")                                                                                                                                                                                                       
end                                                                                                                                                                                                                                              

Response:render("html", "index.html, "string")                                                                                                                                                                                                  

return Response                     
```


template.lua
```lua
local Template = {}                                                                                                                                                                                                                              

function Template:open(file)                                                                                                                                                                                                                     
end                                                                                                                                                                                                                                              

function Template:render(file, params)                                                                                                                                                                                                           
	print("Template:open", file, params)
end                                                                                                                                                                                                                                              

return Template                          
```

如果在执行的路由所对应的匿名函数， 孙数是有返回值的， 如果type(fun_rtn_data) == "table"
告诉Response:render("JSON", fun_rtn_data)按照JSON形式渲染，如果是type(fun_rtn_data) == "string"
告诉Response:render("HTML", fun_rtn_data)按照HTML形式渲染数据。

 下面我们就直接在上面代码的基础上，添加JSON渲染和HTML渲染胡实现。 这两种数据的区
 分地浏览器来说，就是通过设置Http Header来告诉浏览器的，其它的工作最后都是ngx.say
 来完成的。
 
 以下就是几种常用的类型。
 
 
1. 'Content-Type', 'text/html; charset=UTF-8'
2. 'Content-Type', 'text/plain; charset=UTF-8'
3. 'Content-Type', 'application/json; charset=utf-8'
 
 
 一般来说， 使用时意识不到有Response这个库相对比较省心，如果有更复杂或个性的需求
 再显示的调用Resposne类方法。
 
 接下来，我们可以在Template中加入一些常用的模板标签。

Lua WEB框架里，支持标签的有Lapis的etlua模板处理。etlua和django对模板传递变量的方
式不太一样，Lapis的处理方式是直接将要传递的变量给匿名函数的self引用，如下：

app.lua
```lua
app:get("/list", function(self)
	self.list = client.getList()
	return { render = "list_template" }
end)
```

lapis如果return的table里有render这个key,lapis就会去对应渲染view目录下的对应value
值的.etlua文件，文件的大体内容，如下：

list_tempalte.etlua
```lua
<% for i, thing in pairs(list) do%>
    <tr>
        <td>
            <%= thing%>
        </td>
    </tr>
<% end %>
```
这是一个典型的Lapis的例子etlua模板例子，再看看Tenjin模板的例子：

```python
import tenjin
tenjin.set_template_encoding('utf-8')  # optional (defualt 'utf-8')
from tenjin.helpers import *
from tenjin.html import *
engine = tenjin.Engine()
context = { 'items': ['<AAA>', 'B&B', '"CCC"'] }
html = engine.render('example.pyhtml', context)
print(html)
```

Tenjin的Python部份的代码比较有Python特色，先是Import库，创建一个对象，用
object.render方法来渲染一个模板。

```html
<?py # -*- coding: utf-8 -*- ?>
<?py #@ARGS items ?>
<table>
<?py cycle = new_cycle('odd', 'even') ?>
<?py for item in items: ?>
  <tr class="#{cycle()}">
    <td>${item}</td>
  </tr>
<?py #endfor ?>
</table>
```
 这种是直接在模板文件中创建一个函数然后直接调用，tenjin是一个独立的模板系统，还
 可以看看Djano自带的模板。
 
 
Django的Python部分的代码就显得大同小异， 而且相对Tenjin和Lapis在API调用上显得就
有些啰嗦，首先要用loader对象装载模板，其次是用RequestContext给模板传递数据，最后
是把用HttpResponse给浏览返回渲染的数据。

views.py
```python

from django.http import HttpResponse
from django.template import loader
from django.template import RequestContext

def list(request):
        t = loader.get_template('list.html')
        c = RequestContext(request, {
                'url_list':words_list,
        })
        return HttpResponse(t.render(c))
```



```html
<div class="url_list">

{\% block content %}
    <table border="1">
        {% for item in url_list %}
            <tr>
                <td>{{item.id}}</td>
                <td>{{item.title}}</td>
                <td>{{item.content}}</td>
                <td>
                    <a target="blank" href="{{item.content}}">{{item.title}}
                </td>
            </tr>
        {% endfor %}
    </table>
{\% endblock %}
</div>
```


目前来看Django的后端实现的用的代码量是最多的，而Lapis看上去就简洁一些。无论是
Vanilla还是LOR这两个框架都共用了一个部件，就是位于框架Bin目录下的scaffold,这个
程序除了自动生成框架的一些基础代码，还完成了一个工作就是配置nginx的conf文件，用
这个程序做一个简单模板的示意演示。



 LUA
 
 
 PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

