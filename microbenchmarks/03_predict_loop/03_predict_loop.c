// See LICENSE for license details.

//**************************************************************************
// Double-precision sparse matrix-vector multiplication benchmark
//--------------------------------------------------------------------------

#include "util.h"
#include <riscv_vector.h>
#include <string.h>
#include <stdio.h>
#include "sim_api.h"

//--------------------------------------------------------------------------
// Input/Reference Data

#include <stdint.h>
#include "count_utils.h"
#include "sim_api.h"

#define NUM_LOOP 10000

int8_t mem_area[NUM_LOOP * 100] __attribute__ ((section (".bss")));
void test ()
{
  vint8m1_t vtemp;
  int8_t *p_last_mem = 0;
  size_t vl = __riscv_vsetvlmax_e8m1();
  int8_t *mem_base = mem_area;
  for (int loop = 0; loop < NUM_LOOP; loop++) {
    // printf ("loop = %d, addr = %08lx, diff=%lx\n",
    //         loop, mem_base, mem_base - p_last_mem);
    vtemp = __riscv_vadd_vv_i8m1(__riscv_vle8_v_i8m1 (mem_base, vl), vtemp, vl);
    // p_last_mem = mem_base;
    mem_base += 100;
  }

  __riscv_vse8_v_i8m1(mem_area, vtemp, vl);

  return;
}

// int64_t mem_area[10][1000 * 32 * 32] __attribute__ ((section (".bss")));
// void test ()
// {
//   vint64m1_t vtemp;
//   int64_t *p_last_mem = 0;
//   size_t vl = __riscv_vsetvlmax_e64m1();
//   for (int step = 0; step < 10; step++) {
//     int64_t *mem_base = &mem_area[step];
//     for (int loop = 0; loop < 100; loop++) {
//       for (int i = 0; i < step; i++) {
//         printf ("step = %d; loop = %d, i = %d, addr = %08lx, diff=%lx\n",
//                 step, loop, i, mem_base, mem_base - p_last_mem);
//         vtemp = __riscv_vadd_vv_i64m1(__riscv_vle64_v_i64m1 (mem_base, vl), vtemp, vl);
//         p_last_mem = mem_base;
//         mem_base += vl;
//       }
//       mem_base += 128;
//     }
//   }
//   __riscv_vse64_v_i64m1(&mem_area[0], vtemp, vl);
//
//   return;
// }

//--------------------------------------------------------------------------
// Main

int __attribute__((optimize("O0"))) main()
{
  long long start_cycle = get_cycle();
  long long start_vecinst = get_vecinst();

  SimRoiStart();
  start_konatadump();

  test ();

  SimRoiEnd();
  stop_konatadump();

  long long end_cycle = get_cycle();
  long long end_vecinst = get_vecinst();
  // printf("cycles = %lld\n", end_cycle - start_cycle);
  // printf("vecinst = %lld\n", end_vecinst - start_vecinst);

  return 0;

}
