## 关于Promise的延伸

引用：
> https://cnodejs.org/topic/5770ff61bef3ca5c17dee040

> 是不是这样呢?我们层层深入地理解一下 Promise 到底是什么。

> 对于上面这个问题， Promise 是不是只是把callback换个地方写呢？

> 我从《深入浅出Nodejs》 4.3.2 中的一段话收到了启发

> 上面的异步调用中，必须严谨地设置目标。那么是否有一种先执行异步调用，延迟传递处理的方式呢？

> 说的就是传统的callback写法，必须在异步调用的时候，明确地声明回调处理的逻辑。

```js
httpGet('/api',{
	success:onSuccess,
	error:onError
});
```
> 就是说，你必须明确指明了异步调用结束时的各种回调，然后才会执行异步操作

> **（声明异步操作）---> (注册回调) ---> (执行异步操作)**

> 反过来看看 Promise 是不是就不一样呢？先看一段代码

```js
var p = httpGet('/api');

p.then(onSuccess , onError);
```

> 你猜到底在哪一步发起了http请求？

> 正如你猜测的一样，在 p 初始化的时候，这个异步操作就执行了。
> 所以对于Promise来说，流程是这样的

> **（声明异步操作）---> (执行异步操作) ---> (注册回调)**
> 原来真的存在一种方法，先执行异步调用，延迟传递处理的方式。这就是Promise与传统callback一个很显著的区别。

配合文章中关于Promemise的状态变化的例子会有更深的体会

## 起源

> https://zhuanlan.zhihu.com/p/47211041

> Coroutine运作机制类似于state machine，但是写起来和function类似。表达同样的概念用的代码要精简许多。有两种风格的coroutine，一种是用”yield“（也被称为generator），一种是用”async/await“。我们先来看看”yield“如何工作的。

## Continuation

> https://www.zhihu.com/question/20259086

## Linux AIO

### libaio

https://man7.org/linux/man-pages/man7/aio.7.html

### POSIX AIO -- glibc 版本

https://techlog.cn/article/list/10182771

### IO_URING

https://zhuanlan.zhihu.com/p/62682475
https://segmentfault.com/a/1190000019300089

> https://github.com/peigongdh/io_uring-echo-server

## 其他

这个网站给出了非常多语言的echo_server的时间
https://rosettacode.org/wiki/Echo_server