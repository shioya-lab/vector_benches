#include "common.h"
#include <riscv_vector.h>
#include <string.h>
#include "sim_api.h"
#include "count_utils.h"

#define N (32 * 1024 / sizeof(double))
// const int N = 32;
// #define N (128)

// data gen

double A[N] __attribute__((aligned(64))) ;
double golden[N] __attribute__((aligned(64)));
double actual[N] __attribute__((aligned(64)));

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
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  gen_rand_1d(A, N);

  // compute
  memcpy(golden, A, sizeof(A));

  memcpy_vec(actual, A, sizeof(A));

  uint64_t start_cycle;
  uint64_t stop_cycle;
  SimRoiStart();
  start_konatadump();
  memcpy_vec(actual, A, sizeof(A));
  SimRoiEnd();
  stop_konatadump();

  // compare
  puts(compare_1d(golden, actual, N) ? "pass" : "fail");
}
