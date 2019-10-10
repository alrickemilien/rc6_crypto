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

uint8_t*    ww_encrypt(uint8_t*);

void        _ww_set_key(RC6_KEY*, void*, uint32_t);

#define ww_set_key(x, y, z) _ww_set_key(x, y, z)

#endif