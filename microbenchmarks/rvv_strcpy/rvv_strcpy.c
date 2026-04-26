#include "common.h"
#include <assert.h>
#include <riscv_vector.h>
#include <string.h>
#include "sim_api.h"
#include "count_utils.h"

// reference https://github.com/riscv/riscv-v-spec/blob/master/example/strcpy.s
char *strcpy_vec(char *dst, const char *src) {
  char *save = dst;
  size_t vlmax = __riscv_vsetvlmax_e8m8();
  long first_set_bit = -1;
  size_t vl;
  while (first_set_bit < 0) {
    vuint8m8_t vec_src = __riscv_vle8ff_v_u8m8((const unsigned char*)src, &vl, vlmax);

    vbool1_t string_terminate = __riscv_vmseq_vx_u8m8_b1(vec_src, 0, vl);
    vbool1_t mask = __riscv_vmsif_m_b1(string_terminate, vl);

    __riscv_vse8_v_u8m8_m(mask, (unsigned char*)dst, vec_src, vl);

    src += vl;
    dst += vl;

    first_set_bit = __riscv_vfirst_m_b1(string_terminate, vl);
  }
  return save;
}

int __attribute__((optimize("O0"))) main() {
  const int N = 100;
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  char s0[N];
  gen_string(s0, N);

  // compute
  char golden[N], actual[N];
  strcpy(golden, s0);

  strcpy_vec(actual, s0);

  SimRoiStart();
  start_konatadump();
  strcpy_vec(actual, s0);
  SimRoiEnd();
  stop_konatadump();

  // compare
  puts(strcmp(golden, actual) == 0 ? "pass" : "fail");
}
