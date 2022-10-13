#include <stdint.h>

#define DATA_NUM 4096

int32_t mask_data[DATA_NUM/32] = {
  0x01234567, 0x89abcdef, 0x11112222, 0x33334444,
  0x55556666, 0x77778888, 0x9999aaaa, 0xbbbbcccc
};


uint64_t source_data[DATA_NUM];
