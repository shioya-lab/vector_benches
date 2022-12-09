#include "common.h"
#include <assert.h>
#include <riscv_vector.h>
#include <string.h>

// reference https://github.com/riscv/riscv-v-spec/blob/master/example/strcpy.s
char *strcpy_vec(char *dst, const char *src) {
  char *save = dst;
  size_t vlmax = vsetvlmax_e8m8();
  long first_set_bit = -1;
  size_t vl;
  while (first_set_bit < 0) {
    vint8m8_t vec_src = vle8ff_v_i8m8(src, &vl, vlmax);

    vbool1_t string_terminate = vmseq_vx_i8m8_b1(vec_src, 0, vl);
    vbool1_t mask = vmsif_m_b1(string_terminate, vl);

    vse8_v_i8m8_m(mask, dst, vec_src, vl);

    src += vl;
    dst += vl;

    first_set_bit = vfirst_m_b1(string_terminate, vl);
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

  uint64_t start_cycle;
  uint64_t stop_cycle;
  asm volatile ("csrr %0, cycle; add x0, x0, x0":"=r"(start_cycle));
  strcpy_vec(actual, s0);
  asm volatile ("csrr %0, cycle; add x0, x0, x0":"=r"(stop_cycle));

  // compare
  puts(strcmp(golden, actual) == 0 ? "pass" : "fail");
}
