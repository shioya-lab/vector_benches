#include "common.h"
#include <riscv_vector.h>
#include <string.h>
#include "sim_api.h"
#include "count_utils.h"

uint64_t mem_area[128];

// defined in memcpy.S
void main_load(int loop);

int main() {
  const uint32_t seed = 0xdeadbeef;
  srand(seed);

  uint64_t start_cycle;
  uint64_t stop_cycle;
  SimRoiStart();
  start_konatadump();
  for (int i = 0; i < 8; i++) {
    asm volatile ("nop");
  }
  size_t vl = __riscv_vsetvlmax_e64m1();
  vuint64m1_t mem0 = __riscv_vle64_v_u64m1 (&mem_area[0], vl);
  vuint64m1_t mem1 = __riscv_vle64_v_u64m1 (&mem_area[1], vl);
  vuint64m1_t res  = __riscv_vadd_vv_u64m1 (mem0, mem1, vl);
  __riscv_vse64_v_u64m1 (&mem_area[0], res, vl);
  for (int i = 0; i < 1024; i++) {
    asm volatile ("nop");
  }
  SimRoiEnd();
  stop_konatadump();

  return 0;
}
