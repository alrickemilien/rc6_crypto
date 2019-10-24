#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <ctype.h>
#include <inttypes.h>

#include "ww_encrypt.h"

size_t hex2bin(void *bin, const char hex[]);

int main(int argc, const char **argv) {
    RC6_KEY rc6_key;
    size_t  plen, clen, klen;

    uint8_t k[32];
    uint8_t p_in[16], p_out[16];
    uint8_t cypher[32];

    assert(argc == 3);

    memset(k, 0, sizeof(k));
    klen = hex2bin(k, argv[2]);
    assert(klen != 0);
    ww_set_key(&rc6_key, k, klen);

    plen = strlen(argv[1]);
    printf("Encrypt ...\n");

    for (size_t i = 0; i < plen / 16 + 1; i++) {
        memset(p_in, 0, sizeof(p_in));
        memset(p_out, 0, sizeof(p_out));
        memset(cypher, 0, sizeof(cypher));

        if (strlen(argv[2] + 16 * i) >= 16)
            memcpy(p_in, argv[2] + 16 * i, 16);
        else
            memcpy(p_in, argv[2] + 16 * i, strlen(argv[2] + 16 * i));

        ww_encrypt(&rc6_key, p_in, cypher);
        ww_decrypt(&rc6_key, cypher, p_out);

        assert(memcmp(p_in, p_out, 16) == 0);

        for (size_t j = 0; j < 16; j++)
            printf("%02" PRIx8, ((uint8_t*)cypher)[j]);
    }

    printf("\n");

    return (0);
}