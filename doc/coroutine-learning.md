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

### 协程状态机

![](v2-292c3d7220e6667d1db9c033c1d703c2_1440w.png)

### async&await

TODO

## 协程的分类

### 有栈协程与无栈协程

> https://mthli.xyz/stackful-stackless/

## 实现

> https://github.com/peigongdh/coroutinedh

基于共享栈的非对称协程实践

### 关键代码阅读

```c
void
coroutine_resume(struct schedule *S, int id) {
    // ...
    case COROUTINE_READY:
        // 初始化ucontext_t结构体,将当前的上下文放到C->ctx里面
        ctx_getcontext(&C->ctx);
        // 将当前协程的运行时栈的栈顶设置为S->stack
        // 每个协程都这么设置，这就是所谓的共享栈。（注意，这里是栈顶）
        C->ctx.stack = S->stack;
        C->ctx.stack_size = STACK_SIZE;
        // 如果协程执行完，将切换到主协程中执行
        C->ctx.link = &S->main;
        S->running = id;
        C->status = COROUTINE_RUNNING;

        // 设置执行C->ctx函数, 并将S作为参数传进去
        ctx_makecontext(&C->ctx, (int (*)(void *)) mainfunc, (void *) S);

        // 将当前的上下文放入S->main中，并将C->ctx的上下文替换到当前上下文
        ctx_swapcontext(&S->main, &C->ctx);
        break;
    case COROUTINE_SUSPEND:
        // 将协程所保存的栈的内容，拷贝到当前运行时栈中
        // 其中C->size在yield时有保存
        memcpy(S->stack + STACK_SIZE - C->size, C->stack, C->size);
        S->running = id;
        C->status = COROUTINE_RUNNING;
        ctx_swapcontext(&S->main, &C->ctx);
        break;
    // ...
}
```

```c
void
coroutine_yield(struct schedule *S) {
    // ...
    // 将当前运行的协程的栈内容保存起来
    _save_stack(C, S->stack + STACK_SIZE);

    // 将当前栈的状态改为 挂起
    C->status = COROUTINE_SUSPEND;
    S->running = -1;

    // 所以这里可以看到，只能从协程切换到主协程中
    ctx_swapcontext(&C->ctx, &S->main);
    // ...
```

### ucontext库

> https://pubs.opengroup.org/onlinepubs/7908799/xsh/ucontext.h.html

```c
ucontext_t *uc_link     pointer to the context that will be resumed
                        when this context returns
sigset_t    uc_sigmask  the set of signals that are blocked when this
                        context is active
stack_t     uc_stack    the stack used by this context
mcontext_t  uc_mcontext a machine-specific representation of the saved
                        context
```

- 当当前上下文(如使用 makecontext 创建的上下文）运行终止时系统会恢复uc_link指向的上下文；
- uc_sigmask为该上下文中的阻塞信号集合；
- uc_stack为该上下文中使用的栈；
- uc_mcontext保存的上下文的特定机器表示，包括调用线程的特定寄存器等。

```c
int  getcontext(ucontext_t *);
int  setcontext(const ucontext_t *);
void makecontext(ucontext_t *, (void *)(), int, ...);
int  swapcontext(ucontext_t *, const ucontext_t *);
```

> ucontext库解析：https://blog.csdn.net/qq910894904/article/details/41911175

## 函数调用栈

> 参考：https://mthli.xyz/stackful-stackless/

```c
int callee() { // callee:
               //   pushl %ebp
               //   movl  %esp, %ebp
               //   subl  $16, %esp
    int x = 0; //   movl  $0, -4(%ebp)
    return x;  //   movl -4(%ebp), %eax
               //   leave
               //   ret
}

int caller() { // caller:
               //   pushl %ebp
               //   movl  %esp, %ebp
    callee();  //   call  callee
    return 0;  //   movl  $0, %eax
               //   popl  %ebp
               //   ret
}
```

当 caller 调用 callee 时，执行了以下步骤（注意注释中的执行顺序）：

![](caller-to-callee.png)

```c
callee:
    // 3. 将 caller 的栈帧底部地址入栈保存
    pushl %ebp
    // 4. 将此时的调用栈顶部地址作为 callee 的栈帧底部地址
    movl  %esp, %ebp
    // 5. 将调用栈顶部扩展 16 bytes 作为 callee 的栈帧空间；
    //    在 x86 平台中，调用栈的地址增长方向是从高位向低位增长的，
    //    所以这里用的是 subl 指令而不是 addl 指令
    subl  $16, %esp
    ...
caller:
    ...
    // "call callee" 等价于如下两条指令：
    // 1. 将 eip 存储的指令地址入栈保存；
    //    此时的指令地址即为 caller 的 return address，
    //    即 caller 的 "movl $0, %eax" 这条指令所在的地址
    // 2. 然后跳转到 callee
    pushl %eip
    jmp callee
    ...
```

当 callee 返回 caller 时，则执行了以下步骤（注意注释中的执行顺序）：

![](callee-to-caller.png)

```c
callee:
    ...
    // "leave" 等价于如下两条指令：
    // 6. 将调用栈顶部与 callee 栈帧底部对齐，释放 callee 栈帧空间
    // 7. 将之前保存的 caller 的栈帧底部地址出栈并赋值给 ebp
    movl %ebp, %esp
    popl %ebp
    // "ret" 等价如下指令：
    // 8. 将之前保存的 caller 的 return address 出栈并赋值给 eip，
    //    即 caller 的 "movl $0, %eax" 这条指令所在的地址
    popl eip
caller:
    ...
    // 9. 从 callee 返回了，继续执行后续指令
    movl $0, %eax
    ...
```

## 自己实现ucontext


```c
// 保存当前上下文到oucp结构体中，然后激活upc上下文。
int swapcontext(ucontext_t *oucp, ucontext_t *ucp);
```

```c
asm("\
.globl _ctx_swapcontext \n\
.globl ctx_swapcontext \n\
_ctx_swapcontext: \n\
ctx_swapcontext: \n"
#if CTX_OS_WINDOWS || __CYGWIN__
    "movq %rcx, %rax; \n"
#else
    "movq %rdi, %rax; \n"
#endif
    "\n\
    movq %rdx, 24(%rax); \n\
    movq %rax, 0(%rax); \n\
    movq %rbx, 8(%rax); \n\
    movq %rcx, 16(%rax); \n\
    movq %rsi, 32(%rax); \n\
    movq %rdi, 40(%rax); \n\
    leaq 8(%rsp), %rdx; \n\
    movq %rdx, 48(%rax); \n\
    movq %rbp, 56(%rax); \n\
    movq 0(%rsp), %rdx; \n\
    movq %rdx, 64(%rax); \n\
    pushfq; \n\
    popq %rdx;  \n\
    movq %rdx, 72(%rax); \n\
    movq %r8, 80(%rax); \n\
    movq %r9, 88(%rax); \n\
    movq %r10, 96(%rax); \n\
    movq %r11, 104(%rax); \n\
    movq %r12, 112(%rax); \n\
    movq %r13, 120(%rax); \n\
    movq %r14, 128(%rax); \n\
    movq %r15, 136(%rax); \n\
    movq 24(%rax), %rdx; \n\
    stmxcsr 144(%rax); \n\
    fnstenv 152(%rax); \n\
    fldenv 152(%rax); \n"
#if CTX_OS_WINDOWS || __CYGWIN__
    "movq %rdx, %rax\n"
#else
    "movq %rsi, %rax\n"
#endif
    "\n\
    movq 8(%rax), %rbx; \n\
    movq 16(%rax), %rcx; \n\
    movq 24(%rax), %rdx; \n\
    movq 32(%rax), %rsi; \n\
    movq 40(%rax), %rdi; \n\
    movq 48(%rax), %rsp; \n\
    movq 56(%rax), %rbp; \n\
    movq 64(%rax), %rdx; \n\
    pushq %rdx; \n\
    movq 72(%rax), %rdx; \n\
    pushq %rdx; \n\
    popfq; \n\
    movq 80(%rax), %r8; \n\
    movq 88(%rax), %r9; \n\
    movq 96(%rax), %r10; \n\
    movq 104(%rax), %r11; \n\
    movq 112(%rax), %r12; \n\
    movq 120(%rax), %r13; \n\
    movq 128(%rax), %r14; \n\
    movq 136(%rax), %r15; \n\
    movq 24(%rax), %rdx; \n\
    ldmxcsr 144(%rax); \n\
    fldenv 152(%rax); \n\
    movq 0(%rax), %rax; \n\
    ret; \n\
");
```

寄存器保存
> https://en.wikipedia.org/wiki/X86_calling_conventions#Caller-saved_(volatile)_registers

## 函数调用栈

