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

### yield/resume

```lua
local newProducer

function producer()
     local i = 0
     while true do
          i = i + 1
          print(string.format("produce:%d", i))
          send(i)
     end
end

function consumer()
     while true do
          local i = receive()
          print(string.format("consume:%d", i))
     end
end

function receive()
     local status, value = coroutine.resume(newProducer)
     return value
end

function send(x)
     coroutine.yield(x)
end

newProducer = coroutine.create(producer)
consumer()
```

## async/await

```js
async function productor(d) {
    d = d + 1
    console.log("produce:" + d)
    await consumer(d)
}

async function consumer(d) {
    console.log("consume:"+d)
    await productor(d)
}

productor(0).catch(error => console.log(error.stack));
```

执行上面的程序报错：

```
RangeError: Maximum call stack size exceeded
Exception in PromiseRejectCallback:
/Users/zhangpei/mine/coroutine-learning/productor-consumer/productor_consumer.js:4
    await consumer(d)
```

## Generator

> https://zhuanlan.zhihu.com/p/20794401

## Continuation

> https://www.zhihu.com/question/20259086

## asymmetric coroutine & symmetric coroutine

> https://blog.endless7.com/symmetric-and-asymmmetric-coroutine/

> 早在七十年代，Donald Knuth 在他的神作 The Art of Computer Programming 中将 Coroutine 的提出者归于 Conway Melvin。
> 协程(Coroutine)的概念最早由Melvin Conway在1963年提出，指在并发运算中，两个子线程相互协作的过程，用它可以实现协作式的多任务过程。

coroutine可以分为两种

- 非对称式(asymmetric)协程，又称半对称式(semi-asymmetric)协程，半协程(semi-coroutine)
- 对称式(symmetric)协程
- 对称与非对称最主要的区别在于是否存在传递程序控制权的行为

### Asymmetric Coroutine

非对称式(asymmetric)协程之所以被称为非对称的，是因为它提供了两种传递程序控制权的操作：

- coroutine.resume - (重)调用协程
- coroutine.yield - 挂起协程并将程序控制权返回给协程的调用者

一个非对称协程可以看 做是从属于它的调用者的，二者的关系非常类似于例程(routine)与其调用者之间的关系。

### Symmetric Coroutine

对称式协程的特点是只有一种传递程序控制权的操作coroutine.transfer即将控制权直接传递给指定的协程。

曾经有这么一种说法，对称式和非对称式协程机制的能力并不等价，但事实上很容易根据前者来实现后者。在不少动态脚本语言(Python、Perl,Lua,Ruby)都提供了协程或与之相似的机制

### 对比

对称式协程机制可以直接指定控制权传递的目标，拥有极大的自由，但得到这种自由的代价却是牺牲程序结构。如果程序稍微复杂一点，那么即使是非常有经验的程序员也很难对程序流程有全面而清晰的把握。这非常类似goto语句，它能让程序跳转到任何想去的地方，但人们却很难理解充斥着goto的程序。非对称式协程具有良好的层次化结构关系，(重)启动这些协程与调用一个函数非常类似：被(重)启动的协程得到控制权开始执行，然后挂起(或结束)并将控制权返回给协程调用者。这与结构化编程风格是完全一致的

其实，非对称在于程序控制流转移到被调协程时使用的是 call/resume 操作，而当被调协程让出 CPU 时使用的却是 return/yield 操作。此外，协程间的地位也不对等，caller 与 callee 关系是确定的，不可更改的，非对称协程只能返回最初调用它的协程。

对称协程（symmetric coroutines）则不一样，启动之后就跟启动之前的协程没有任何关系了。协程的切换操作，一般而言只有一个操作 — yield，用于将程序控制流转移给另外的协程。对称协程机制一般需要一个调度器的支持，按一定调度算法去选择 yield 的目标协程。

Go 语言提供的协程，其实就是典型的对称协程。除了对称，Goroutines 还可以在多个线程上迁移。这种协程跟操作系统中的线程非常相似，甚至可以叫做“用户级线程”了。

## stackless coroutine & stackful coroutine

> https://jiajunhuang.com/articles/2018_04_03-coroutine.md.html

### stackless coroutine

> 基于Duff's device的无栈协程：https://www.chiark.greenend.org.uk/~sgtatham/coroutines.html
> 上面的译文：https://mthli.xyz/coroutines-in-c/
> zhihu上基于Duff's device的无栈协程 https://zhuanlan.zhihu.com/p/32312942

### stackful coroutine

### 对比



### ucontext

> https://www.jianshu.com/p/4f7d3aa83088
> https://blog.csdn.net/qq910894904/article/details/41911175

> manual: https://pubs.opengroup.org/onlinepubs/7908799/xsh/ucontext.h.html

### 汇编实现简单的ucontext

> 仿ucontext api实现： https://zhuanlan.zhihu.com/p/32431200
> ucontext源码分析：https://segmentfault.com/p/1210000009166339/read

### cloudwu-coroutine

> 云风的协程库源码分析：https://www.cyhone.com/articles/analysis-of-cloudwu-coroutine/

## coroutine实现分类

> 三种coroutine实践：https://zhuanlan.zhihu.com/p/25513336

## Linux AIO

### libaio

https://man7.org/linux/man-pages/man7/aio.7.html

### POSIX AIO -- glibc 版本

https://techlog.cn/article/list/10182771

### IO_URING

https://zhuanlan.zhihu.com/p/62682475
https://segmentfault.com/a/1190000019300089

> https://github.com/peigongdh/io_uring-echo-server

### libco

> https://www.cyhone.com/articles/analysis-of-libco/
> https://blog.didiyun.com/index.php/2018/11/23/libco/

## 其他

这个网站给出了非常多语言的echo_server的时间
https://rosettacode.org/wiki/Echo_server
