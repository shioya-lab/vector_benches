#include "common.h"
#include <riscv_vector.h>
#include "sim_api.h"
#include "count_utils.h"

// index arithmetic
void index_golden(double *a, double *b, double *c, int n) {
  for (int i = 0; i < n; ++i) {
    a[i] = b[i] + (double)i * c[i];
  }
}

void index_(double *a, double *b, double *c, int n) {
  size_t vlmax = vsetvlmax_e32m1();
  vuint32m1_t vec_i = vid_v_u32m1(vlmax);
  for (size_t vl; n > 0; n -= vl, a += vl, b += vl, c += vl) {
    vl = vsetvl_e64m2(n);

    vfloat64m2_t vec_i_double = vfwcvt_f_xu_v_f64m2(vec_i, vl);

    vfloat64m2_t vec_b = vle64_v_f64m2(b, vl);
    vfloat64m2_t vec_c = vle64_v_f64m2(c, vl);

    vfloat64m2_t vec_a =
        vfadd_vv_f64m2(vec_b, vfmul_vv_f64m2(vec_c, vec_i_double, vl), vl);
    vse64_v_f64m2(a, vec_a, vl);

    vec_i = vadd_vx_u32m1(vec_i, vl, vl);
  }
}

int __attribute__((optimize("O0")))
main() {
  const int N = 31;
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  double B[N], C[N];
  gen_rand_1d(B, N);
  gen_rand_1d(C, N);

  // compute
  double golden[N], actual[N];
  index_golden(golden, B, C, N);

  uint64_t start_cycle;
  uint64_t stop_cycle;
  for (int i = 0; i < 2; i++) {
    if (i == 1) {
      SimRoiStart();
      start_konatadump();
    }
    index_(actual, B, C, N);
    if (i == 1) {
      SimRoiEnd();
      stop_konatadump();
    } else {
      asm volatile ("fence");
    }
  }

  // compare
  puts(compare_1d(golden, actual, N) ? "pass" : "fail");
}
