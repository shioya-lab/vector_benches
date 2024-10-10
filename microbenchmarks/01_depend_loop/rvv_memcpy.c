#include "common.h"
#include <riscv_vector.h>
#include <string.h>
#include "sim_api.h"
#include "count_utils.h"

// defined in memcpy.S
void main_load(int loop, uint64_t *area);

uint64_t area [1000 * 0x100 / 8];

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
  main_load (1000, area);
  SimRoiEnd();
  stop_konatadump();

  return 0;
}
