---
layout: post
title: Lapis快速分页查询
date:   2017-01-16 17:00:18 +0800 
categories: candylab
---

作者：糖果

Lapis分页查询和一般的Django分页查询有明显的分别：

lapis分页器对象的创建和查询条件的指定是同时的。

```lua
local lapis = require "lapis"
local app = lapis.Application()
local config = require("lapis.config")

local db = require("lapis.db")
local Model = require("lapis.db.model").Model
local schema = require ("lapis.db.schema")

app:get("/",
function(self)
   
    local Cmt = Model:extend("user")
    local paginated = Cmt:paginated("where id <= ?" , 100, { per_page = 10,
        prepare_results = function(posts)
        return posts
    end

    local page1 = paginated:get_page(1)
end
)
```


不像Django，Lapis不需要定义表的结构类，一句就可以解决这个问题：
```
local Cmt = Model:extend("user")
```


接下来就是定义分页模式, 查询条件是id<=100, 10行分一页：
```lua
    local paginated = Cmt:paginated("where id <= ?" , 100, { per_page = 10,
        prepare_results = function(posts)
        return posts
    end
```


查询第一分页数据：
```lua
     local page1 = paginated:get_page(1)
```

lapis分页接口这样设计是可以接受的：

看一下Python的接口设计：
```python
def listing(request):
        words_list = Author.objects.order_by('-dateTime')[:100]
        paginator = Paginator(words_list, 16)
        page = request.GET.get('page')

        try:
                contacts = paginator.page(page)
        except PageNotAnInteger:
                contacts = paginator.page(1)
        except EmptyPage:
                contacts = paginator.page(paginator.num_pages)

        t = loader.get_template('tests/list.html')

        c = RequestContext(request, {
                'words_list':contacts,
        })
        return HttpResponse(t.render(c))

```

把直接从Model里取出的数据全集，直接给分页器，当分页器持有这些数据后，通过自己的接口，来操作返回分页的数据结果。

在Django中,第一次正常的查询动作和分页动作执行是分开的，先按条件查询，返回所有数据集合，然后，再作为入参给分页器对像。

而Lapis的方式是二和一的，赋予查询条件查询和返回结果给分页，是一个动作，model和分页器，不是两个数据结构，是一个对象控制的，这是好还是不好呢？各有好处！


www.candylab.net


PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net


