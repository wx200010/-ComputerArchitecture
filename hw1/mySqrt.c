#include <stdio.h>
#include <stdint.h>
uint32_t my_clz(uint32_t x)
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

int mySqrt(unsigned x)
{
  if (x == 0)
    return x;

  uint32_t temp, L, R, M;
  temp = 31 - my_clz(x); // using clz method to find the MSB location - 1 of x
  // printf("temp = %d\n", temp);
  L = 1 << (temp >> 1); // set initial min as 2 ^ ((MSB location-1) / 2)
  R = L << 1;           // set initial max as 2 ^ (((MSB location-1) / 2) + 1)

  while (1)
  {
    M = (L + R) >> 1;
    // printf("L, M, R = %d, %d, %d\n", L, M, R);
    if (M * M > x)
      R = M;
    else if ((M + 1) * (M + 1) <= x) // can do M*M + 2*M + 1 in assembly
      L = M;
    else
      return M; // return M when M*M <= x < (M+1)*(M+1)
  }
}
int main()
{
  uint32_t datas[] = {0, 1, 2, 4, 8, 2147483647};
  uint32_t results[] = {
      mySqrt(datas[0]),
      mySqrt(datas[1]),
      mySqrt(datas[2]),
      mySqrt(datas[3]),
      mySqrt(datas[4]),
      mySqrt(datas[5])};

  for (int i = 0; i < 6; ++i)
    printf("\nmySqrt(%u) is : %u", datas[i], results[i]);
}