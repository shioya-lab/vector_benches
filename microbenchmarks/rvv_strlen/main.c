#include <stdio.h>
#include <stdint.h>

void copy_data_vec(int8_t *dest_data, int8_t *source_data, int data_num);
void copy_data_mask_vec(int8_t *dest_data, int8_t *source_data, int8_t *mask, int data_num);

#include "data.h"

int32_t vec_data[DATA_NUM] = {0};
int32_t scalar_data[DATA_NUM] = {0};

void format_array()
{
  for (int i = 0; i < DATA_NUM; i++) {
    vec_data[i] = 0;
    scalar_data[i] = 0;
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

  const int data_num = DATA_NUM * sizeof(int32_t) / sizeof(int8_t);
  copy_data_vec   ((int8_t *)vec_data,    (int8_t *)source_data, data_num);

  // return check_data((int64_t *)vec_data, (int64_t *)scalar_data, DATA_NUM * sizeof(int32_t) / sizeof(int64_t));
  return 0;
}

int test_vl()
{
  format_array();

  const int data_num = DATA_NUM * sizeof(int32_t) / sizeof(int8_t) - 10;
  // fprintf(stderr, "start test_vl\n");
  copy_data_vec   ((int8_t *)vec_data,    (int8_t *)source_data, data_num);
  copy_data_scalar((int8_t *)scalar_data, (int8_t *)source_data, data_num);

  return check_data((int64_t *)vec_data, (int64_t *)scalar_data, DATA_NUM * sizeof(int32_t) / sizeof(int64_t));
}

// int test_mask()
// {
//   format_array();
//
//   const int data_num = DATA_NUM * sizeof(int32_t) / sizeof(int8_t);
//   fprintf(stderr, "start test_mask\n");
//   copy_data_mask_vec((int8_t *)vec_data,    (int8_t *)source_data, (int8_t *)mask_data, data_num);
//   copy_data_mask_scalar ((int8_t *)scalar_data, (int8_t *)source_data, (int8_t *)mask_data, data_num);
//
//   return check_data((int64_t *)vec_data, (int64_t *)scalar_data, DATA_NUM * sizeof(int32_t) / sizeof(int64_t));
// }
