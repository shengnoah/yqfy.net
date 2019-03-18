---
layout: post
title: LUA PCRE安装(Lrexlib)
date:   2017-06-13 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png

tag:
- openresty 
- Lrexlib
- lua
- pcre

---
Lrexlib是PCRE的Lua调用库。在此说一下 Lrexlib的安装过程。


Ubuntu下安装：

1.首先是安装依赖。
```
apt-get install libpcre3
apt-get install libpcre3-dev
```

2.建立连接。
Ubuntu安装的是pcre3，安装完之后系统内才能有libpcre.so的库。
apt-get安装的库文件没有在/usr/lib文件夹下，需要建立连接。

```
ln -s /lib/x86_64-linux-gnu/libpcre.so.3 /usr/lib/libpcre.so
```

3.使用luarocks安装PCRE。
```
sudo luarocks install lrexlib-PCRE PCRE_LIBDIR=/usr/lib/
```

4.测试库。
```
lua -e "require 'rex_pcre'"
```


Centos下安装PCRE：


1.首先是安装依赖。
```
yum install pcre
yum install pcre-devel
```

2.建立连接。
```
ln -s  /usr/lib64/libpcre.so /usr/lib
```

3.使用luarocks安装PCRE。

需要特别说明的地方是，在centos上安装2.8是编译不过的，需要指定2.7.2版本的安装。
```
luarocks install lrexlib-pcre 2.7.2-1 PCRE_LIBDIR=/usr/lib64/
```

4.测试库。
```
lua -e "require 'rex_pcre'"
```

5. PCRE正侧在线解析工具。


[regex101](https://regex101.com/)

[regexpal](http://www.regexpal.com/)



```
Character classes
.	any character except newline
\w \d \s	word, digit, whitespace
\W \D \S	not word, digit, whitespace
[abc]	any of a, b, or c
[^abc]	not a, b, or c
[a-g]	character between a & g
Anchors
^abc$	start / end of the string
\b	word boundary
Escaped characters
\. \* \\	escaped special characters
\t \n \r	tab, linefeed, carriage return
\u00A9	unicode escaped ©
Groups & Lookaround
(abc)	capture group
\1	backreference to group #1
(?:abc)	non-capturing group
(?=abc)	positive lookahead
(?!abc)	negative lookahead
Quantifiers & Alternation
a* a+ a?	0 or more, 1 or more, 0 or 1
a{5} a{2,}	exactly five, two or more
a{1,3}	between one & three
a+? a{2,}?	match as few as possible
ab|cd	match ab or cd
```



https://luarocks.org/modules/luarocks/lrexlib-pcre


作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net
