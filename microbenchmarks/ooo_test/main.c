#include <stdio.h>
#include <stdint.h>

volatile int64_t store_data[128];

int test_0()
{
  for (int i = 0; i < 128; i++) {
    uint64_t st_addr;
    asm volatile ("div %0, %1, %2":"=r"(st_addr) :   "r"(i), "r"(1));

    store_data[st_addr] = i;
    store_data[i];
  }
  return 0;
}

volatile int64_t store_data1[128];
volatile int64_t load_data1 [128];
int test_1()
{
  int count = 1;
  for (int i = 0; i < 128; i++) {
    uint64_t st_addr;
    asm volatile ("div %0, %1, %2":"=r"(st_addr) :   "r"(i), "r"(1));

    store_data1[st_addr] = i;
    asm volatile ("mul %0, %1, %2":"=r"(count) :   "r"(count), "r"(count));
  }
  return 0;
}


int main()
{
  // 1st: Cache cold
  uint64_t start_cycle;
  uint64_t stop_cycle;
  // asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(start_cycle));
  test_0();
  // asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(stop_cycle));
  // 2nd: Cache warmed up
  // asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(start_cycle));
  test_0();
  // asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(stop_cycle));


  // 1st: Cache cold
  // asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(start_cycle));
  test_1();
  // asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(stop_cycle));
  // 2nd: Cache warmed up
  asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(start_cycle));
  test_1();
  asm volatile ("csrr %0, cycle; add x0,x0,x0":"=r"(stop_cycle));

  return 0;
}
