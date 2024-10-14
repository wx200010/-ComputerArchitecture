#include <stdio.h>
#include <stdint.h>
static inline uint32_t my_clz(uint32_t x)
{
  int r = 0, c;
  c = (x < 0x00010000) << 4;
  r += c;
  x <<= c; // off 16

  c = (x < 0x01000000) << 3;
  r += c;
  x <<= c; // off 8

  c = (x < 0x10000000) << 2;
  r += c;
  x <<= c; // off 4

  c = (x >> (32 - 4 - 1)) & 0x1e;
  return r + ((0x55af >> c) & 3);
}

static inline uint32_t fp16_to_fp32(uint16_t h)
{
  const uint32_t w = (uint32_t)h << 16;
  const uint32_t sign = w & UINT32_C(0x80000000);
  const uint32_t nonsign = w & UINT32_C(0x7FFFFFFF);
  uint32_t renorm_shift = my_clz(nonsign);
  renorm_shift = renorm_shift > 5 ? renorm_shift - 5 : 0;
  const int32_t inf_nan_mask = ((int32_t)(nonsign + 0x04000000) >> 8) &
                               INT32_C(0x7F800000);
  const int32_t zero_mask = (int32_t)(nonsign - 1) >> 31;
  return sign | ((((nonsign << renorm_shift >> 3) +
                   ((0x70 - renorm_shift) << 23)) |
                  inf_nan_mask) &
                 ~zero_mask);
}

int main()
{
  uint32_t input1 = 0xFFFF;
  uint32_t input2 = 0x0710;
  uint32_t input3 = 0x80F3;
  uint32_t result1 = fp16_to_fp32(input1);
  uint32_t result2 = fp16_to_fp32(input2);
  uint32_t result3 = fp16_to_fp32(input3);
  printf("\nresult1 is : %d ", result1);
  printf("\nresult2 is : %d ", result2);
  printf("\nresult3 is : %x ", result3);
}