#ifndef WW_ENCRYPT_H
# define WW_ENCRYPT_H

/*
** Header description for asm functions
*/

# include <stdint.h>

#define RC6_ROUNDS 20
#define RC6_KR     (2*(RC6_ROUNDS+2))
#define RC6_P      0xB7E15163
#define RC6_Q      0x9E3779B9

#define RC6_ENCRYPT 1
#define RC6_DECRYPT 0

typedef struct _RC6_KEY {
  uint32_t x[RC6_KR];
} RC6_KEY;

void        _ww_set_key(RC6_KEY*, void*, uint32_t);
void        _ww_crypt(RC6_KEY*, void*, void*, int);

#define ww_set_key(x, y, z) _ww_set_key(x, y, z)
#define ww_encrypt(x, y) _ww_crypt(x, y, RC6_ENCRYPT)
#define ww_decrypt(x, y) _ww_crypt(x, y, RC6_DECRYPT)

#endif