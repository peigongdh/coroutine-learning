function schedule(task)
    has_more, msg, args = coroutine.resume(task)
    if (not has_more) then
        return
    end
    if (msg == 'sleep') then
        os.execute("sleep " .. args.seconds)
    end
    schedule(task)
end

function sub1_task()
    print(os.time(), 'step1')
    coroutine.yield('sleep', {seconds=2})
    print(os.time(), 'step2')
    coroutine.yield('sleep', {seconds=2})
    print(os.time(), 'step3')
end

task = coroutine.create(sub1_task)
schedule(task)
-- output
-- 1540106451	step1
-- 1540106453	step2
-- 1540106455	step3