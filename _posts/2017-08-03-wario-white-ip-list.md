---
layout: post
title:  Wario中实现IP白名单插件
date:   2017-08-03 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- header-plugin
- wario
- blues
---

有黑名单插件就有白名单插件。

代码：
 
 
```lua

local sink = {
    name = "whitelist_plugin",
    ver = "0.1"
}

local ip_list = {
}

function whitelist_plugin.output(self, list, flg)
    if flg == 0 then return end
    for k,v in pairs(list) do print(k,v) end
end


function whitelist_plugin.push(self, stream)
    for k,v in pairs(stream.metadata) do
        self.source[k]=v
    end 
end

function whitelist_plugin.init(self)
    self.source = src
    self.sink = sink
    self.ip_list = ip_list
end

function whitelist_plugin.action(self, stream) 
    local buffer = require "buffer"
    local whiteip_list = buffer.gett("white_list")
    local flg = true    

    for k,v in pairs(whiteip_list) do
        local aip =  ngx.var.remote_addr
        if v['RuleItem'] == stream.request.ip then
            ngx.log(ngx.ERR, 'white_list')
            flg = false 
            break
        end
    end

    if flg then
        ngx.exit(404)
    end

end


function whitelist_plugin.match(self, param)
    self.sink['found_flg']=false
    for k,v in pairs(self.source) do
         self.sink[k] = v
    end
    self:action(self.sink)
    return self.source, self.sink
end

return whitelist_plugin
```




作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net




