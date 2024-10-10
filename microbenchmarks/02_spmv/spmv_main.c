// See LICENSE for license details.

//**************************************************************************
// Double-precision sparse matrix-vector multiplication benchmark
//--------------------------------------------------------------------------

#include "util.h"
#include <string.h>
#include <stdio.h>
#include "sim_api.h"

//--------------------------------------------------------------------------
// Input/Reference Data

// #include "dataset2.h"
// #include "dataset1.h"
// #include "dataset_small.h"
#include <stdint.h>
// #include "dataset_2048x2048x0_25.h"
#include "dataset_128x1024x0_05.h"
#include "count_utils.h"
#include "sim_api.h"

void spmv(int r, const double* val, const uint64_t* idx, const double* x,
          const uint64_t* ptr, double* y)
{
  for (int i = 0; i < r; i++)
  {
    int k;
    y[i] = 0.0;
    for (k = ptr[i]; k < ptr[i+1]; k++) {
      y[i] += val[k]*x[idx[k]];
    }
  }
}

#ifdef USE_RISCV_VECTOR
void spmv_vector(
	int r,
	const double* val,
	const uint64_t* idx,
	const double* x,
	const uint64_t* ptr, double* y);
#endif // USE_RISCV_VoECTOR

//--------------------------------------------------------------------------
// Main

#define PREALLOCATE

int __attribute__((optimize("O0"))) main()
{
  double y[R];

#ifdef PREALLOCATE
#ifdef USE_RISCV_VECTOR
  spmv_vector(R, val, idx, x, ptr, y);
#else // USE_RISCV_VECTOR
  spmv(R, val, idx, x, ptr, y);
#endif // USE_RISCV_VECTOR
#endif

  long long start_cycle = get_cycle();
  long long start_vecinst = get_vecinst();

  SimRoiStart();
  start_konatadump();
#ifdef USE_RISCV_VECTOR
  spmv_vector(R, val, idx, x, ptr, y);
#else // USE_RISCV_VECTOR
  spmv(R, val, idx, x, ptr, y);
#endif // USE_RISCV_VoECTOR
  SimRoiEnd();
  stop_konatadump();

  long long end_cycle = get_cycle();
  long long end_vecinst = get_vecinst();
  printf("cycles = %lld\n", end_cycle - start_cycle);
  printf("vecinst = %lld\n", end_vecinst - start_vecinst);

  int result = verifyDouble(R, y, verify_data);
  if (!result) {
    printf("Pass\n");
  } else {
    printf("Error\n");
  }
  return result;
}
