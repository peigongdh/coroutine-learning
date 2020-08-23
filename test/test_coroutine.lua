function foo(n)
    local i = 0
    while i < 5 do
        local id, status = coroutine.running()
        print(id, n + i)
        coroutine.yield()
        i = i + 1
    end
end

function test()
    local co1 = coroutine.create(foo)
    local co2 = coroutine.create(foo)
    print("main start")
    coroutine.resume(co1, 0)
    coroutine.resume(co2, 100)
    while coroutine.status(co1) ~= "dead" and coroutine.status(co2) ~= "dead" do
        coroutine.resume(co1)
        coroutine.resume(co2)
    end
    print("main end")
end

test()