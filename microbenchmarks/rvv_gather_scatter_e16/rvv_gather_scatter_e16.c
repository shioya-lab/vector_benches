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


uint64_t gather16(const uint16_t* val, const uint16_t* idx_ptr, uint64_t n)
{
  size_t vlmax = vsetvlmax_e16m1();
  vuint16m1_t v_zero = vmv_v_x_u16m1(0, vlmax);
  vuint16m1_t v_y    = vmv_v_x_u16m1(0, vlmax);
  size_t vl = 0;

  for (; n > 0; n -= vl) {
    vl = vsetvl_e16m1(n);
    vuint16m1_t v_idx = vle16_v_u16m1(idx_ptr, vl);
    vuint16m1_t v_x   = vluxei16_v_u16m1(val, v_idx, vl);

    v_y = vadd_vv_u16m1(v_y, v_x, vl);

    val += vl;
    idx_ptr += vl;
  }
  vuint16m1_t v_y_m1 = vredsum_vs_u16m1_u16m1 (v_y_m1, v_y, v_zero, vlmax);
  return vmv_x_s_u16m1_u16 (v_y_m1);
}


int __attribute__((optimize("O0"))) main() {

  uint64_t result = gather16 (v_data16, v_index16, 16);
  printf("1st try: result = %ld\n", result);

  SimRoiStart();
  start_konatadump();
  result = gather16 (v_data16, v_index16, 16);
  SimRoiEnd();
  stop_konatadump();

  printf("result = %ld\n", result);

  return 0;
}
