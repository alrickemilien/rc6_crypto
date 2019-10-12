#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
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

size_t hex2bin (void *bin, const char hex[]) {
  size_t len, i;
  int x;
  uint8_t *p=(uint8_t*)bin;
  
  len = strlen (hex);
  
  if ((len & 1) != 0) {
    return 0; 
  }
  
  for (i=0; i<len; i++) {
    if (isxdigit((int)hex[i]) == 0) {
      return 0; 
    }
  }
  
  for (i=0; i<len / 2; i++) {
    sscanf (&hex[i * 2], "%2x", &x);
    p[i] = (uint8_t)x;
  } 
  return len / 2;
} 


int test_set_key(void) {
    RC6_KEY rc6_key;
    int     key_len;
    uint8_t k[32];

    for (int i = 0; i < sizeof(test_keys) / sizeof(char*); i++)
    {
        memset (k, 0, sizeof (k));

        key_len = hex2bin(k, test_keys[i]);

        printf("test_keys[%2d]: %64s - key_len %d\n", i, test_keys[i], key_len);

        ww_set_key(&rc6_key, k, key_len);
    }

    return (0);
}

int main(void)
{
    test_set_key();
    return (0);
}