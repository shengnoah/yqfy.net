---
layout: post
title: 匿名函数在WEB路由解析过程中的作用
date:   2016-12-06 11:00:18 +0800 
categories: candylab
---
作者：糖果

Lua不直接支持面向对象的特性， 但是可以用现有Lua的特性模拟OO，下面是一个用Lua的仿
OO的类来展示WEB路由的工作过程，简单说WEB路由的主要要完成的任务是，相符一定规则的
URL字符串与后端程序的某个函数对应。就像WAF防火墙，一个正规对应一个动作处理函数是
一个道理。


lua中比较常提的一个特性就meta table，翻译过来就是元表，meata、metadata很多时候是
表示对象或是被描述的主题的一些特性（属性和行为），其中有一个meta属性是__call，下面是一个说明的例
子。

下面的例子，是让一个独立table变量与一个独立函数相关联。如果有C的经验，可以感受到
有些像struct结构变量通过fucntion pointer与function产生关系类似。

```lua
function foo(tb, x, y)
    for k,v in pairs(tb) do
        print(k,v)
    end
    return x+y+tb.n
end

function foo_add(tbl,x, y)
        return x + y
end

function foo_sub(x, y)
        return x - y
end

src_def_tbl = {}
src_def_tbl.__call = foo

print(type(src_def_tbl.__call))
```

值得注意的是print(type(tbl.__call)，打印出的类弄还是function,一个function pointer。

__call只是元表属性多个属性中的一个，上面的变量与函数定义，类似一个声明的过程，但
产将这些属性行为集成到一个新的table实例上，这时就需要一个setmetatable关键字来完成
这个工作。

setmetatalbe(dst_tbl_name, src_define_tbl_name)

setmetatalbe有两个形参，左数第一个是要被赋予新意义数的table变量:dst_tbl_name, 而
src_define_tbl_name，之前特殊定义的一些变量和函数关系的属性行为声明table,上面的
代码，着重是定义了__call属性，使其指向一个函数。


```lua
dst_tbl = {}

function dst_tbl:test()
        print("dst_tbl:test")
end

dst_tbl.n = 12
dst_tbl.m = 34

setmetatable(dst_tbl, src_def_tbl)
```

在重新定义了metatable后，我们可以直接用dst_tbl()的形式调用函数，这种类似构造函数
的调用，都执行几个隐含的操作动作。

1.会调用foo()函数。
2.会把dst_tbl中所有变量和函数直接做为第一个table类型的参数传给src_def_tbl.foo函
数。

这样就类似把foo函数变成了构造函数调用，第一个传进来的参数相当于self或是this指针。

foo(dst_tbl, x, y)与dst_tbl(dst_tbl, x, y)是等效调用。


上面的两上table，dst_tbl和src_def_tbl是两个并存的table变量，不存在包含的关系。
如果我们采用下面声明方式，在一个table变量A的持有函数方法中，新建一个table变量
B，将B._call指向A的A.handle函数, 通过setmetatable设置，A.handle函数，变成B变量
的类构造函数调用模式，B也可以通过B()等效调用了handle函数，函数的第一个参数，就是
A变量所有的变量和函数传给了B，然后把B变量返回，就完成了一次“对象”实例化的过程。

```lua
local app = {}

function app:new()
    local instance = {}
    instance.m = 100
    instance.n = 500
    setmetatable(instance, {
        __index = self,
        __call = self.dispatch
    })

    instance:initMethod()
    return instance
end

function app:handle(req, res, callback)
    print(req)
    print(res)
    print(callback)
end

function app:output(path, fn)
    print(path)
    print(fn)
end

function app:initMethod()
    self["get"] = function()
        print("app:get")
    end
end

return app
```


匿名函数的作用，就将URL路径字符串和匿名函数，作为两具体的形参传对象实例的一个函
数方法，上面的代码，是WEB框架的最外层代码，不是路由处理模块的代码，router作为路
由处理代码，持用get，post函数方法，Lor的方式是这样，其它的框架率有不同。

匿名函数做为形参传给get或是post,路由管理会把这些匿名函数声明和URL数据集中，一旦
有用户的HTTP Request请求，就取出用户URL和这些收集到的URL和函数表进行对表，表现URL
配对，就调用对应的函数。而实际上，就是来一个请求，将类似的get方法都执行一遍，与
url模式批配就执行函数。


App实例一般是整个框架的入口，如果在new函数中.__call指向了handle函数， handle函数
持有所有框架部件的数据，当然就包括了用户的请求，session和cookie等信息，而路由检
查处理部分也可以单独抽出一个类。


下面这段代码，是类似Lapis的调用过程。

```lua
app = require"app"

local router = app:new()
router:get("/test",
function(req, res)
      print("abc")
      print(req, res)
end
)
--obj:handle("abc","efg","hij")
```

下面是路由处理部分，我们也可以考虑一下，.__call这种调用形式，如果用moonscript是
如何完成的呢。


再进入路由之前，还有两个元函数.__tostring和.__toindex这个两个函数。


__tostring就是当你要print输出一个table类型的数据时，print会去检查你要打印的这个
table变量的元表中是否定义了函数，换句话说就是__tostring是否指向一个函数，如果没
指向函数，值为nil时，print是无法打印这个table变量中的内容的，如果你指定的函数
并且把self做为形参，这个__tostring所提向的函数就可以得到当前table变量所有的数据
引用，相当于this引用，下面代码就是用来说明__string的使用的。

```lua
src_def_tbl = {}

function constructor(this, req, res)
        for k,v in pairs(this) do
                print(k.." ")
                print(v)

        end
end

src_def_tbl.__call = constructor
src_def_tbl.__tostring = function (self) return self.value.." ".."test tostring" end

dst_tbl = {}
dst_tbl.value = "prefix"

function dst_tbl:output()
        print("output")
end

setmetatable(dst_tbl, src_def_tbl)
dst_tbl(100,500)
print(dst_tbl)
```

最直观表示URL和函数的关系就是二维表：
当用请求有新的URL时，发生的URL配置对应函数的过程就是查表的过程 。

下面是Django中,通过一个URL对应函数的List,建立起函数处理与URL之间的联系。
```python
from django.conf.urls import url
urlpatterns = [
 url(r'one/$', 'testcase.case.one'),
 url(r'two/$', 'testcase.case.two'), 
 url(r'three/$', 'testcase.case.three'), 
]

def one(request):
    return HttpResponse("one", mimetype='application/json')
dfef two(request):
    return HttpResponse("one", mimetype='application/json')
def three(request):
    return HttpResponse("one", mimetype='application/json')
```

而Flask是直接将路由和函数对应的更近。

```python
from flask import render_template
from app import app
 
@app.route('/one')
def one():
    map = { 'url': 'function' } 
    return render_template("index.html", map = map, title = 'one')
    
@app.route('/two')
def two():
    map = { 'url': 'function' } 
    return render_template("index.html", map = map, title = 'two')
    
@app.route('/three')
def three():
    map = { 'url': 'function' } 
    return render_template("index.html", map = map, title = 'three')
    
```

Tornado也进通过表的形式建立URL和函数之间的联系。


```python
import tornado.web
import tornado.wsgi
class one(tornado.web.RequestHandler):
    def get(self):
        self.write("one")

class two(tornado.web.RequestHandler):
    def get(self):
        self.write("two")
        
class three(tornado.web.RequestHandler):
    def get(self):
        self.write("three")

urls = [
    (r"/one", one),
    (r"/two", two),
    (r"/three", three)
]
```

如果把这种(“字符串”或是“ID”)与“函数”关系抽像出来，也可以是一种查表模式。
换成CPP模式，如果触发函数执行的不是HTTP Request请求形成的URL更新，而是由
某种Event的EventID发更触发的函数执行,是EventId和函数之间的映射关系。

```
Event Trigger Process
Event_ID Function_Name Function_Pointer Function_Parameter
1   ONE     &ONE    VOID
2   TWO     &TWO    VOID
3   THREE   &THREE  VOID

URL Trigger Process
URL Function_name Function_pointer Function_Parameter
/ONE    ONE     @ONE    Request
/TWO    TWO     @TWO    Request
/THREE    THREE     @THREE    Request
```

延用简单工厂模式，需要一个主工程类，包含或是引用其它服务子类, 下面是伪
CPP代码：
```c
struct Map_type {
    UINT32 event_id;
    void* fptr;
}


truct Map a = {
        UINT32 one, void* fptr_one ;
        UINT32 two, void* fptr_two;
        UINT32 three, void* fptr_three;        
}

class CSession {
    void CSesson(void);
    return void;
}

class CRouter {
    void CRouter(void) {
        return void;
    }
    
    funType* doEvent(EventID) { // EventID->URL
        return (FunType*)searchFunctionMap(EventID);
    }
}

class CApp {
    void CApp(void) {
        session = new CSession();
        router = new CRouter();
        return void;
    }
    
    void Handle(request, callback) {
        return void;
    }
}
```

CPP要通过函数指针或引用建立与函数关系，是一种函数指针指向函数地址的关系，
而Lua或是MoonScript是支持匿名函数的， 不引用其它的模式，就用最简单，动态
构建查表。


这个原型最本质上对数据结构及操作是把url和对应的funciton指针动态的插入到
table变量里，可以考虑在插入时就判断url是否符合定义，执行函数动作，也可
以将所有的url和函数全部插入到table变量中，最后集中的与当前用户请求的url
进行比较，如果命令中就执行对应的函数。

```lua
local tinsert = tfable.insert
map = {}

function test()
    print("test")
end

--tinsert(map, {"/test", test})
function output()
for k,v in pairs(map) do
    print(v[1])
    print(type(v[2]))
        v[2]()
end
end

function register(uri, callback)
        tinsert(map, {uri, callback})
end


register("/one", function() print "one" end)
register("/two", function() print "two" end)
register("/three", function() print "three" end)


uri = "/one"

function run()
    for k,v in pairs(map) do
        print(v[1])
        --print(type(v[2]))
        v[2]()
    end
end

run()
```

除了register的行为，还应有match等行， 抽象最基本的模式就的工厂和查表，上面的函数
都是全局的，没有类与类，变量与变量之间的耦合，没有魔法,没有闭包，也没有基于权限
控制的参数传递，够简单，看一眼有就能明白， 没有对复杂问题的，分类抽象，也没有分
层，出问题可以快速定位问题在呢，多用循环少判断，别浪费机器周用。

可以把处理按层来分，也可以按stream来分，也可以是pipleline。

我们用lua的setmetadata方式重新组织一上面的代码，分出两大处理，构建基本的主框架类
Application,实同一个最简单的，基于查表模式的router,rule对应action，url对应函数的
声明模式。

下面我们实现个最小化的路由：

```lua
local tinsert = table.insert
local Route =  {}

function Route:Init()
end

function Route:getInstance()
        local instance = {}
        instance.map = {}
        instance.id = 1

        local base = {}
        function base.register(this, uri, callback)
                tinsert(this.map, {uri, callback})
        end

        base.__call = base.register
        setmetatable(instance, base)
        return instance
end

function Route:register(request, uri, callback)
        tinsert(self.map, {uri, callback})
end

function Route:match()
end

router = Route:getInstance()
router("/one", function()
        print "one"
end)

router("/two", function()
        print "two"
end)

router("/three", function()
        print "three"
end)

Route:match()
function run()
    for k,v in pairs(router.map) do
        print(v[1])
        v[2]()
    end
end

run()
```

可以用同样的模式组织Application（主类）的代码,上面的代码没有区分，用户Http Request
请求的类型。先来实现Application类,让Application持有router。对于WAF来说，HTTP数据
对她来说都是可见的，策略的意义是告诉他主动过滤什么数据，执行什么动作。

router最后管理了一张表数据，输出是表数据，也可以看成是一个有src、filter、sink的
数据通道。

感觉已经有些跑偏了，重起一篇接着写。

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
