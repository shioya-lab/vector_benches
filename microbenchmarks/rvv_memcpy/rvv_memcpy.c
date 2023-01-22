#include "common.h"
#include "count_cycles.h"
#include <riscv_vector.h>
#include <string.h>

void *memcpy_vec(void *dst, void *src, size_t n) {
  void *save = dst;
  // copy data byte by byte
  for (size_t vl; n > 0; n -= vl, src += vl, dst += vl) {
    vl = vsetvl_e8m8(n);
    vuint8m8_t vec_src = vle8_v_u8m8(src, vl);
    vse8_v_u8m8(dst, vec_src, vl);
  }
  return save;
}

int __attribute__((optimize("O0"))) main() {
  const int N = 32 * 1024 / sizeof(double);
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  double A[N];
  gen_rand_1d(A, N);

  // compute
  double golden[N], actual[N];
  memcpy(golden, A, sizeof(A));

  memcpy_vec(actual, A, sizeof(A));

  uint64_t start_cycle;
  uint64_t stop_cycle;
  asm volatile ("csrr %0, cycle; add x0, x0, x0":"=r"(start_cycle));
  start_konatadump();
  memcpy_vec(actual, A, sizeof(A));
  stop_konatadump();
  asm volatile ("csrr %0, cycle; add x0, x0, x0":"=r"(stop_cycle));

  // compare
  puts(compare_1d(golden, actual, N) ? "pass" : "fail");
}
