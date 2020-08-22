## 定义

> Coroutines are computer program components that generalize subroutines for non-preemptive multitasking, by allowing execution to be suspended and resumed. 

> 译：协程是计算机程序组件，通过允许挂起和恢复执行来概括非抢先式多任务处理的子例程。

## 生产者消费者

### yield&resume

```lua
local newProducer

function producer()
     local i = 0
     while true do
          if i >= 5 then
               break
          end
          i = i + 1
          print(string.format("produce:%d", i))
          send(i)
     end
end

function consumer()
     while true do
          local i = receive()
          print(string.format("consume:%d", i))
          if i >= 5 then
               break
          end
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

执行结果
```
produce:1
consume:1
produce:2
consume:2
produce:3
consume:3
produce:4
consume:4
produce:5
consume:5
```

### async&await

TODO