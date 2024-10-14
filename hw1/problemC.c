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
  uint32_t datas[] = {
      0x0710, // normalized number
      0x311F, // normalized number
      0x000F, // denormalized number
      0x0000, // positive zero
      0x8000, // negative zero
      0x7C00, // positive inf
      0xFC00, // negative inf
      0x7CFF  // NaN
  };
  uint32_t results[] = {
      fp16_to_fp32(datas[0]),
      fp16_to_fp32(datas[1]),
      fp16_to_fp32(datas[2]),
      fp16_to_fp32(datas[3]),
      fp16_to_fp32(datas[4]),
      fp16_to_fp32(datas[5]),
      fp16_to_fp32(datas[6]),
      fp16_to_fp32(datas[7])};

  printf("\nfp16_to_fp32(0x0710) is : 0x%x ", results[0]); // normalized number
  printf("\nfp16_to_fp32(0x311F) is : 0x%x ", results[1]); // normalized number
  printf("\nfp16_to_fp32(0x000F) is : 0x%x ", results[2]); // denormalized number
  printf("\nfp16_to_fp32(0x0000) is : 0x%x ", results[3]); // positive zero
  printf("\nfp16_to_fp32(0x8000) is : 0x%x ", results[4]); // negative zero
  printf("\nfp16_to_fp32(0x7C00) is : 0x%x ", results[5]); // positive inf
  printf("\nfp16_to_fp32(0xFC00) is : 0x%x ", results[6]); // negative inf
  printf("\nfp16_to_fp32(0x7CFF) is : 0x%x ", results[7]); // NaN
}