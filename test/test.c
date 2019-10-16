#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <inttypes.h>
#include "ww_encrypt.h"

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

const char *test_plaintexts[] ={
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1" 
};

const char *test_ciphertexts[] ={
  "8fc3a53656b1f778c129df4e9848a41e",
  "524e192f4715c6231f51f6367ea43f18",
  "6cd61bcb190b30384e8a3f168690ae82",
  "688329d019e505041e52e92af95291d4",
  "8f5fbd0510d15fa893fa3fda6e857ec2",
  "c8241816f0d7e48920ad16a1674e5d48"
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


int test_set_key(void) {
    RC6_KEY rc6_key;
    size_t  plen, clen, klen;

    uint8_t k[32];
    uint8_t c_in[32], c_out[32];
    uint8_t p_in[32], p_out[32];

    for (size_t i = 0; i < sizeof(test_keys) / sizeof(char*); i++)
    {
        memset(p_in, 0, sizeof(p_in));
        memset(p_out, 0, sizeof(p_out));
        memset(c_in, 0, sizeof(c_in));
        memset(c_out, 0, sizeof(c_out));
        memset(k, 0, sizeof(k));

        klen = hex2bin(k, test_keys[i]);
        clen = hex2bin(c_in, test_ciphertexts[i]);
        plen = hex2bin(p_in, test_plaintexts[i]);

        printf("test_keys[%2ld]: %64s - klen %ld\n", i, test_keys[i], klen);

        printf("Set key ...\n");

        ww_set_key(&rc6_key, k, klen);

        printf("test_keys[%2ld] - content of rc6_key:", i);
        for (size_t i = 0; i < klen; i++)
          printf(" %" PRIu32, rc6_key.x[i]);
        printf("\n\n");

        printf("Encrypt ...\n");

        ww_encrypt(&rc6_key, p_in, c_out);

        assert(memcmp(c_in, c_out, clen) == 0);

        printf("Decrypt ...\n");

        ww_decrypt(&rc6_key, c_out, p_out);

        assert(memcmp(p_in, p_out, plen) == 0);
    }

    return (0);
}

int main(void)
{
    test_set_key();
    return (0);
}