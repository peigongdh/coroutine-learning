local client_future = nil

function send_recv(task, req)
    local future = {task=task, req=req}
    client_future = future
    coroutine.yield()
    return future.resp
end

function sub1_task(task)  
    print('step1')
    print(send_recv(task, 'some fake request'))
    print('step2')
end

task = coroutine.create(sub1_task)
coroutine.resume(task, task)
-- pretend we have sent the request
print(client_future.req)
-- pretend we have recevied the request
client_future.resp = 'some fake response'
coroutine.resume(task)

-- output
-- step1
-- some fake request
-- some fake response
-- step2