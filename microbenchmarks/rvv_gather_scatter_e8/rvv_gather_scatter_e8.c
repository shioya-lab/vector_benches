#include "data8.h"
#include "data16.h"
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
  size_t vlmax = vsetvlmax_e8m1();
  vuint8m1_t v_zero = vmv_v_x_u8m1(0, vlmax);
  vuint8m1_t v_y    = vmv_v_x_u8m1(0, vlmax);
  size_t vl = 0;

  for (; n > 0; n -= vl) {
    vl = vsetvl_e8m1(n);
    vuint8m1_t v_idx = vle8_v_u8m1(idx_ptr, vl);
    vuint8m1_t v_x   = vluxei8_v_u8m1(val, v_idx, vl);

    v_y = vadd_vv_u8m1(v_y, v_x, vl);

    val += vl;
    idx_ptr += vl;
  }
  vuint8m1_t v_y_m1 = vredsum_vs_u8m1_u8m1 (v_y_m1, v_y, v_zero, vlmax);
  return vmv_x_s_u8m1_u8 (v_y_m1);
}



int __attribute__((optimize("O0"))) main() {

  uint64_t result = gather8 (v_data8, v_index8, 128);
  printf("1st try: result = %ld\n", result);

  SimRoiStart();
  start_konatadump();
  result = gather8 (v_data8, v_index8, 128);
  SimRoiEnd();
  stop_konatadump();

  printf("result = %ld, cycle = %ld, vecinst = %ld\n", result, end_cycle - start_cycle, end_vecinst - start_vecinst);

  return 0;
}
