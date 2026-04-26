#include "data8.h"
#include "data16.h"
#include "sim_api.h"
#include "count_cycles.h"
#include <riscv_vector.h>
#include <stdio.h>
#include <string.h>

// index arithmetic
void index_golden(double *a, double *b, double *c, int n) {
  for (int i = 0; i < n; ++i) {
    a[i] = b[i] + (double)i * c[i];
  }
}


uint64_t gather8(const uint8_t* val, const uint8_t* idx_ptr, uint64_t n)
{
  size_t vlmax = __riscv_vsetvlmax_e8m1();
  vuint8m1_t v_zero = __riscv_vmv_v_x_u8m1(0, vlmax);
  vuint8m1_t v_y    = __riscv_vmv_v_x_u8m1(0, vlmax);
  size_t vl = 0;

  for (; n > 0; n -= vl) {
    vl = __riscv_vsetvl_e8m1(n);
    vuint8m1_t v_idx = __riscv_vle8_v_u8m1(idx_ptr, vl);
    vuint8m1_t v_x   = __riscv_vluxei8_v_u8m1(val, v_idx, vl);

    v_y = __riscv_vadd_vv_u8m1(v_y, v_x, vl);

    val += vl;
    idx_ptr += vl;
  }
  vuint8m1_t v_y_m1 = __riscv_vredsum_vs_u8m1_u8m1(v_y, v_zero, vlmax);
  return __riscv_vmv_x_s_u8m1_u8(v_y_m1);
}



int __attribute__((optimize("O0"))) main() {

  uint64_t result = gather8 (v_data8, v_index8, 128);
  printf("1st try: result = %ld\n", result);

  long long start_cycle = get_cycle();
  long long start_vecinst = get_vecinst();
  SimRoiStart();
  start_konatadump();
  result = gather8 (v_data8, v_index8, 128);
  SimRoiEnd();
  stop_konatadump();
  long long end_cycle = get_cycle();
  long long end_vecinst = get_vecinst();

  printf("result = %ld, cycle = %ld, vecinst = %ld\n", result, end_cycle - start_cycle, end_vecinst - start_vecinst);

  return 0;
}
