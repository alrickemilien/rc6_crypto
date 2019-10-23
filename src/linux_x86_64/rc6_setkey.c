#include "rc6.h"

void rc6_setkey (RC6_KEY *key, void *K, uint32_t keylen)
{  
  uint32_t i, j, k, A, B, L[8], *kptr=(uint32_t*)K; 
  
  // initialize L with key
  for (i=0; i<keylen/4; i++) {
    L[i] = kptr[i];
  }
  
  A=RC6_P;
  
  // initialize S with constants
  for (i=0; i<RC6_KR; i++) {
    key->x[i] = A;
    A += RC6_Q;
  }
  
  A=B=i=j=k=0;
  
  // mix with key
  for (; k < RC6_KR*3; k++)
  { 
    A = key->x[i] = ROTL32(key->x[i] + A+B, 3);  
    B = L[j]      = ROTL32(L[j] + A+B, A+B);
    
    i++;
    i %= RC6_KR;
    
    j++;
    j %= keylen/4;
  } 
}

const char *test_keys[] = {
  "00000000000000000000000000000000",
  "0123456789abcdef0112233445566778",
  "00000000000000000000000000000000"
  "0000000000000000",
  "0123456789abcdef0112233445566778"
  "899aabbccddeeff0",
  "00000000000000000000000000000000"
  "00000000000000000000000000000000",
  "0123456789abcdef0112233445566778"
  "899aabbccddeeff01032547698badcfe"
};

size_t hex2bin (void *bin, const char hex[]) {
  size_t  len, i;
  int     x;
  uint8_t *p;
  
  p = (uint8_t*)bin;
  len = strlen (hex);
  
  if ((len & 1) != 0)
    return (0); 
  
  for (i=0; i<len; i++) {
    if (isxdigit((int)hex[i]) == 0)
      return (0); 
  }
  
  for (i=0; i<len / 2; i++) {
    sscanf (&hex[i * 2], "%2x", &x);
    p[i] = (uint8_t)x;
  } 

  return (len / 2);
} 

int main(void) {
    RC6_KEY rc6_key;
    size_t  klen;

    uint8_t k[32];

    for (size_t i = 0; i < sizeof(test_keys) / sizeof(char*); i++)
    {
        memset(k, 0, sizeof(k));

        klen = hex2bin(k, test_keys[i]);

        printf("test_keys[%2ld]: %64s - klen %ld\n", i, test_keys[i], klen);

        printf("Set key ...\n");

        rc6_setkey(&rc6_key, k, klen);

        printf("test_keys[%2ld] - content of rc6_key:", i);
        for (size_t j = 0; j < RC6_KR * sizeof(uint32_t); j++)
            printf("%02" PRIx8, ((uint8_t*)rc6_key.x)[j]);
        printf("\n\n");
    }

    return (0);
}