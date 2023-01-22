#include <stdio.h>
#include <stdint.h>

void copy_data_vec(int8_t *dest_data, int8_t *source_data, int data_num);
void copy_data_mask_vec(int8_t *dest_data, int8_t *source_data, int8_t *mask, int data_num);

#include "data.h"

void format_array()
{
  for (int i = 0; i < DATA_NUM-1; i++) {
    source_data[i] = &source_data[(i + (DATA_NUM / 4)) % DATA_NUM];
  }
}


int check_data (const int64_t *vec_data, const int64_t *scalar_data, const int data_num)
{
  for(int i = 0; i < data_num; i++) {
    if(vec_data[i] != scalar_data[i]) {
      return i + 1;
    }
  }
  return 0;
}


void copy_data_scalar(int8_t *dest_data, int8_t *source_data, const int data_num)
{
  for (int i = 0; i < data_num; i++) {
    dest_data[i] = source_data[i];
  }
}


void copy_data_mask_scalar(int8_t *dest_data, int8_t *source_data, int8_t *mask, const int data_num)
{
  for (int i = 0; i < data_num; i++) {
    dest_data[i] = ((mask[i/8] >> (i%8)) & 0x1) ? source_data[i] : 0;
  }
}


int test_0();
int test_vl();
// int test_mask();

int main()
{
  // fprintf(stderr, "hogegege main()\n");

  if (test_0() != 0) {
    return 10;
  }
  // if (test_vl() != 0) {
  //   return 20;
  // }
  // if (test_mask() != 0) {
  //   return 30;
  // }
  return 0;
}


int test_0()
{

  format_array();
  uint64_t rd = source_data[0];
  for (int i = 0; i < DATA_NUM-1; i++) {
    asm volatile ("ld %0, 0(%1)": "=r"(rd) : "r"(rd));
  }

  return 0;
}
