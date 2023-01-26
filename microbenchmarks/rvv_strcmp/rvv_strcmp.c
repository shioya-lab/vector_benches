#include "common.h"
#include <riscv_vector.h>
#include <string.h>
#include "sim_api.h"
#include "count_utils.h"

// reference https://github.com/riscv/riscv-v-spec/blob/master/example/strcmp.s
int strcmp_vec(const char *src1, const char *src2) {
  size_t vlmax = vsetvlmax_e8m2();
  long first_set_bit = -1;
  size_t vl, vl1;
  while (first_set_bit < 0) {
    vint8m2_t vec_src1 = vle8ff_v_i8m2(src1, &vl, vlmax);
    vint8m2_t vec_src2 = vle8ff_v_i8m2(src2, &vl1, vlmax);

    vbool4_t string_terminate = vmseq_vx_i8m2_b4(vec_src1, 0, vl);
    vbool4_t no_equal = vmsne_vv_i8m2_b4(vec_src1, vec_src2, vl);
    vbool4_t vec_terminate = vmor_mm_b4(string_terminate, no_equal, vl);

    first_set_bit = vfirst_m_b4(vec_terminate, vl);
    src1 += vl;
    src2 += vl;
  }
  src1 -= vl - first_set_bit;
  src2 -= vl - first_set_bit;
  return *src1 - *src2;
}

int __attribute__((optimize("O0"))) main() {
  const int N = 1023;
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  char s0[N], s1[N];
  gen_string(s0, N);
  gen_string(s1, N);

  // compute
  int golden, actual;
  golden = strcmp(s0, s1);

  actual = strcmp_vec(s0, s1);

  SimRoiStart();
  start_konatadump();
  actual = strcmp_vec(s0, s1);
  SimRoiEnd();
  stop_konatadump();

  // compare
  puts(golden == actual ? "pass" : "fail");
}
