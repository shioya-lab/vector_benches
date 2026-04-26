#include "common.h"
#include <riscv_vector.h>
#include "sim_api.h"
#include "count_utils.h"

// branch and assign
void branch_golden(double *a, double *b, double *c, int n, double constant) {
  for (int i = 0; i < n; ++i) {
    c[i] = (b[i] != 0.0) ? a[i] / b[i] : constant;
  }
}

void branch(double *a, double *b, double *c, int n, double constant) {
  // Use the naming from the ratified RVV intrinsic spec (GCC exposes __riscv_*).
  size_t vlmax = __riscv_vsetvlmax_e64m1();
  vfloat64m1_t vec_constant = __riscv_vfmv_v_f_f64m1(constant, vlmax);
  for (size_t vl; n > 0; n -= vl, a += vl, b += vl, c += vl) {
    vl = __riscv_vsetvl_e64m1(n);

    vfloat64m1_t vec_a = __riscv_vle64_v_f64m1(a, vl);
    vfloat64m1_t vec_b = __riscv_vle64_v_f64m1(b, vl);

    vbool64_t mask = __riscv_vmfne_vf_f64m1_b64(vec_b, 0, vl);

    vfloat64m1_t vec_c = __riscv_vfdiv_vv_f64m1_mu(
        mask, /*maskedoff=*/vec_constant, vec_a, vec_b, vl);
    __riscv_vse64_v_f64m1(c, vec_c, vl);
  }
}

int __attribute__((optimize("O0"))) main() {
  const int N = 31;
  const double constant = 7122.0;
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  // data gen
  double A[N], B[N];
  gen_rand_1d(A, N);
  gen_rand_1d(B, N);
  for (int i = 0; i < 5; ++i) {
    int pos = rand() % N;
    B[pos] = 0;
  }

  // compute
  double golden[N], actual[N];
  branch_golden(A, B, golden, N, constant);
  branch(A, B, actual, N, constant);

  SimRoiStart();
  start_konatadump();
  for (int i = 0; i < 2; i++) {
    branch(A, B, actual, N, constant);
  }
  SimRoiEnd();
  stop_konatadump();

  // compare
  puts(compare_1d(golden, actual, N) ? "pass" : "fail");
}
