local sleep_future = nil

function schedule()
    print(os.time(), 'schedule1')
    if (not sleep_future) then
        return
    end
    task, args = table.unpack(sleep_future)
    os.execute("sleep " .. args.seconds)
    sleep_future = nil
    has_more, msg, args = coroutine.resume(task)
    if (not has_more) then
        return
    end
    schedule()
end

function sleep(task, args)
    print(os.time(), 'sleep1')
    sleep_future = {task, args}
    coroutine.yield()
    print(os.time(), 'sleep2')
end

-- function sleep(task, args)
--     return function(task)
--         sleep_future = {task, args}
--         continue.yield()
--     end
-- end

function sub1_task(task)
    print(os.time(), 'step1')
    sleep(task, {seconds=2})
    print(os.time(), 'step2')
    sleep(task, {seconds=2})
    print(os.time(), 'step3')
end

print(os.time(), 'main1')
task = coroutine.create(sub1_task)
print(os.time(), 'main2')
coroutine.resume(task, task)
print(os.time(), 'main3')
schedule()

-- output
-- 1540127720	step1
-- 1540127723	step2
-- 1540127725	step3