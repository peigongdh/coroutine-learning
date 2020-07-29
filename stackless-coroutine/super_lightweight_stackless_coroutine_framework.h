#define BEGIN_CORO void operator()() { switch(next_line) { case 0:
#define YIELD next_line=__LINE__; break; case __LINE__:
#define END_CORO }} int next_line=0