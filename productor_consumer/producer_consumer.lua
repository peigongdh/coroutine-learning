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