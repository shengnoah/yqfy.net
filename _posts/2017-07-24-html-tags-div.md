---
layout: post
title:  HTML布局标签
date:   2017-07-24 10:00:18 +0800 
categories: candylab
feature: /assets/img/some-image.png
project: true


tag:
- openresty 
- html
- div
---



网页制作的过程中，难免要对网页中的元素进行排版布局。最开始的时候，流行的方法是用Table标签进行网页布局。因为，众所周知的原因：“速度”。表格标签在嵌套过多的时候，网页在显示的时候会变慢。人们就开始使用Div标签进行布局。
表格是现实生活中最常见的二维表示形式，很好理解。从个人角度来看，表格表示一行一行的明细信息的时候，很方便。但在，纵向首先描述“列”的时候，Div标签更合适，更灵活一些。

下面列出，类似表格行明细的Div实现代码。

CSS样式：
```css
<style>
    .afooter {
        float : none;
        alignment-adjust: center;    
    }
   
    .afooter-list {
        float : left;
        alignment-adjust: center;    
    }
    
    .afooter-list-bottom {
        float : none;
        alignment-adjust: center;    
    }
</style>
```

HTML代码：（演示1）
```css
<div class="afooter">
    <div class="afooter-list">a</div>
    <div class="afooter-list">b</div>
    <div class="afooter-list">c</div>
    <div class="afooter-list">d</div>
    <div class="afooter-list-bottom">e</div>
</div>
<div class="afooter">
    <div class="afooter-list">e</div>
    <div class="afooter-list">f</div>
    <div class="afooter-list">g</div>
    <div class="afooter-list">h</div>
    <div class="afooter-list-bottom">i</div>
</div>   
```


上面这段代码，用Table标签写，如下：（演示3）

```html
<table>
    <tr>
        <td>a</td>
        <td>b</td>
        <td>c</td>
        <td>d</td>
        <td>e</td> 
        
    </tr>
    <tr>
        <td>h</td>
        <td>i</td>
        <td>j</td>
        <td>h</td> 
        <td>i</td>        
    </tr>
</table>
```

其实，所谓的灵活，是指代码从机制给你提供了灵活操作的可能，在这个基础上来讲，运用的灵活不灵活，取决于人编码者。

CSS样式：
```html
<style>
    .cfooter {
        float : left;
        alignment-adjust: center;               
    }    
    
    
    .cfooter-list {
        float : none;
        alignment-adjust: center;               
    }    
    
    .cfooter-list-bottom {
        float : none;
        alignment-adjust: center;               
    }     
    
  
    .dfooter {
        float : none;
        alignment-adjust: center;               
    }    
    
    
    .dfooter-list {
        float : none;
        alignment-adjust: center;               
    }    
    
    .dfooter-list-bottom {
        float : none;
        alignment-adjust: center;               
    }      
    
</style>
```

HTML代码：（演示2）

```html
    <div class="cfooter">
        <div class="cfooter-list">1</div>
        <div class="cfooter-list">2</div>
        <div class="cfooter-list">3</div>
        <div class="cfooter-list">4</div>    
    </div>

    <div class="dfooter">
        <div class="dfooter-list">5</div>
        <div class="dfooter-list">6</div>
        <div class="dfooter-list">7</div>
        <div class="dfooter-list">8</div>    
    </div>
</div>  
```

这里可能需要多说的是，每个Div层次，在默认的时候，每个Div元素都是需要换行的。每个Div元素都不在一行，但是这个可以情况可以通过改变CSS样式来改变，如上面代码中的“float : none;”属性设置。在这篇代码里，float的left表示，后面的div元素，紧接着其后不换行，而none属性表示，先一个div层开始，div元素就换行了，不在一行了。

Div比较灵活，至于怎么运用，取决于编码者。可以用Div表示类似于表格的明细信息，也可以应用于比较复杂的图片布局。


使用DIV实现一个登录框：


这次主要是说，网页中Div嵌套的布局处理方式。而应用的场合是，网站的登录框。下面，就分别给出了，网站元素的样式和Html标签代码。


CSS样式代码,如下：
```html
 <style>
.outside{
    float: left;
    padding: 0;
    margin: 1px 0 0 1px;
	width: 230px;
	height:320px;
	border:1px solid #F00;
	background-image:url(/static/yqfy/img/login_background.png)
}

.inside {
    float: left;
    padding: 0;
    margin: 30px 0px 0px 40px;
	width:150px;
	height:130px;
	border:1px solid #F00;
}


.login_username {
    float: right;
    padding: 0;
    margin: 0 0 0 1px;
    background : none ;
    font-size: .8em;
    text-align:center;
    background-color: black;     
    border-spacing: 1px;
    border: 1px;
    border-radius: 1px;
    color:cornsilk
}
    
.login_password {
    float: right;
    padding: 0;
    margin: 1px 0 0 1px;
    background : none ;
    font-size: .8em;
    text-align:center;
    background-color: black;     
    border-spacing: 1px;
    border: 1px;
    border-radius: 1px;
    color:cornsilk
}
 </style>
```

Html代码如下：
```html
 <div class="outside">
 	outside
 	<div class="inside">
 		inside
        <form action="" method='post' >
            <div class="login_box">
            	<div class="div_input">
                	<img src="/static/yqfy/img/login.jpg" alt="login" />
                </div>                           
                <div class="div_input">
                	<input class="login_username" name='username' type="text"  width="75px" height="50px" placeholder="用户名" >          
                </div>
                <div class="div_input">
                	<input class="login_password" name='password' type="password"  width="75px" height="50px" placeholder="密码" >
                </div>		
            </div>
                            
         	<div class="div_input">
            	<button class="login_btn" type="submit">登录</button>
         	</div>
         </form>
	</div>
 </div>
```


总结：
css+html标签，本质上还是“设定”，这种设定主要集中在，样式颜色，位置，等。而以上的例子，关键的属性设定是margin属性。div中设定div好理解，关键点在于，如何设定嵌套在一起啊的div彼此位置关系的设定，所以，div的css的关键是：margin。



Div的布局问题解决了，接下来我们使用自定义标签，来解决过多的Div造成视觉上的混乱的问题：



```
<!DOCTYPE html>
<html>
<head>
	<title>自定义标签</title>
<style>
    article { 
        background-color: #fff; 
        color: #333333; 
        alignment-adjust: center;    
        float: middle;
        padding: 1;
        border:0px solid #00F;        
    }
    
    article header {
       color:#ff6501; 
    }    

    article content {
       /*float: left;*/
       color:#ff00ff;
    }
    
    article content h1 {
        text-decoration: underline        
    }

    article footer {
       color:#0f11ff; 
    }
</style>
</head>
<body>
    
<article>
    <header id='1'>
        test_A
    </header>

    <content id='2'>
        <h1>
        test_B
        </h1>
    </content>
        
    <footer id='3'>
        test_C   
    </footer>

</article>
        
</body>
</html>

```



作者：糖果

PS:转载到其它平台请注明作者姓名及原文链接，请勿用于商业用途。

[糖果实验室](http://www.candylab.net)

http://www.candylab.net

