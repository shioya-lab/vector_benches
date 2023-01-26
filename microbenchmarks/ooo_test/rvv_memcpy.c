#include "common.h"
#include <riscv_vector.h>
#include <string.h>

// compute
const int N = 127;
double golden[127];
double actual[127];

void *memcpy_vec(void *dst, void *src, size_t n) {
  void *save = dst;
  // copy data byte by byte
  for (size_t vl; n > 0; n -= vl, src += vl, dst += vl) {
    vl = vsetvl_e8m1(n);
    vuint8m1_t vec_src = vle8_v_u8m1(src, vl);
    vse8_v_u8m1(dst, vec_src, vl);
  }
  return save;
}

int main() {
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  double A[N];
  gen_rand_1d(A, N);

  // compute
  memcpy(golden, A, sizeof(A));

  SimRoiStart();
  start_konatadump();
  memcpy_vec(actual, A, sizeof(A));
  SimRoiEnd();
  stop_konatadump();

  // compare
  puts(compare_1d(golden, actual, N) ? "pass" : "fail");
}

//uint64_t init = 1231243424;
//
//int main ()
//{
//  uint32_t count = 0;
//  while (init > 1) {
//    init = init / 17;
//    count ++;
//  }
//
//  printf("count = %d\n", count);
//  return 0;
//}
