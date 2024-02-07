#include "write_hit_exclusive.h"
#include <stdint.h>
#include "encoding.h"
#include "test_utils.h"

extern void exit(int);

volatile cacheline_t data[CACHE_WAYS * CACHE_ENTRIES] __attribute__((section(".cache_share_region")));

void prepare()
{
  for (int i = 0; i < sizeof(data)/sizeof(data[0]); i++)
    data[i] = i+1;
}

int write_hit_exclusive(int cid, int nc)
{
  if (cid == 0) {
    prepare();
    warm(unrolled_write, 2);
    profile(unrolled_write, 1);
    exit(0);
  }

  return 0;
}