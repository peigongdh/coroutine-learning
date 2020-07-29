#include <iostream>
#include "super_lightweight_stackless_coroutine_framework.h"

struct SomeCoroutine {
	int n_; // Add whatever you want
	SomeCoroutine(int n) : n_(n) {}
	
	BEGIN_CORO;
	std::cout << "coroutine" << n_ << " hello 1" << std::endl;
	YIELD;
	std::cout << "coroutine" << n_ << " hello 2" << std::endl;
	YIELD;
	std::cout << "coroutine" << n_ << " hello 3" << std::endl;
	END_CORO;
};

int main() {
	SomeCoroutine co1(1);
	SomeCoroutine co2(2);
	co1();
	co2();
	co1();
	co2();
	co1();
	co2();
}