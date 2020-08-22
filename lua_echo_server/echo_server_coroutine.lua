-- simple non-blocking echo server
-- depends on luasocket and its /etc/dispatch.lua

local dispatch = require("dispatch")
local handler  = dispatch.newhandler()    -- 得到一个 handler，对应了一个 readfds, writefds

local host = arg[1] or "*"
local port = arg[2] or 12321

local server = assert(handler.tcp())
assert(server:setoption("reuseaddr", true))
assert(server:bind(host, port))
assert(server:listen(32))
handler:start(function() -- start() 中包裹的函数，就是一个 coroutine 的内容
    while true do
        local client = assert(server:accept())    -- accept, read, write 都是 non-blocking 的
        print("peer connected:", client)          -- 通过 coroutine 让其看起来是 block 的
        assert(client:settimeout(0))
        handler:start(function()
            while true do
                local line, err = client:receive()
                if err and err == 'closed' then
                    print("peer closed:", client)
                    return
                end
                assert(client:send(line.."\n"))
            end
        end)
    end
end)

print(string.format("server start: %s:%d ...", host, port))
while true do
    handler:step()    -- 内部 socket.select()，并分发事件
end