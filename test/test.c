#include <assert.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>
#include <inttypes.h>
#include "ww_encrypt.h"

#define RC6_ROUNDS 20
#define RC6_KR     (2*(RC6_ROUNDS+2))
#define RC6_P      0xB7E15163
#define RC6_Q      0x9E3779B9

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

const char *test_keys_load[] = {
  "2a66311c9b17852d8108b20739d14185"
  "9c64df5f4bed6bcdb1d887264e6ee8c6"
  "66f7fa9c429c2724c955b6bf9306e49a"
  "75524dd956f4da3c5ec06b9babbc779b",

  "05479d38e4a3e582fbcc7a4be878faa4"
  "8ed149805f5873fdaec05ae6aafffe1d"
  "6bf8b7e364e2768223c4d46fda521c4b"
  "662b9392c51ae971be84587a473c1481",

  "483f34e8beff4b1fccd3227b65f94ec2"
  "7401fcedca0a13d9913654cb1ab91fd3"
  "dfb19060822d527abe1781ccc4e16d5f"
  "61634eb1a419bc4d2f6a48e721b16cd6"
  "3f34c1766fa6fa761d90b27acc14532a"
  "2389128f04d088c3122c5888115132ac",

  "04d80adec85296a3c7ca853cd665bea0"
  "4d34492fe110bf659f4acf83eb85cb10"
  "f9f0f8eb2275ea3fe5dc8714a1b4b8b4"
  "1a28cd0a618fbe876fc1ede08eaf634d"
  "7d213901bed7ab7379ba092e6179bc8a"
  "aa35b6f60091b3ca65f970e9687e9e94",

  "65e01b1bb580202e58edcc0e03fde54f"
  "60e1eaf9f28027800bed7bdfb77ce169"
  "eb3c65698ceeb874eb0f30a89d75b3af"
  "a69cbfd8bf0c6cfa47ffb9c53912205a"
  "024584d8cd99593953686a6ad03fcdc9"
  "230ef513911fec26773273abce8457ac"
  "cc75e2d342701aed8c49423326e86c7a"
  "1d68bdd8386d86b3ab027179a22e0011",

  "8d4eee346ca3559dcac74d45c00a874a"
  "5f034ef9e5ffbcf4ee57ded7120160d7"
  "19d36d384292f8b560cfb203d5ad7ce2"
  "5e043e957922e9b0a1ee23349c6787aa"
  "21cb2309c6cd835ef65f68ba7c74a515"
  "249e93359ed327da6cd53e603e0a1a13"
  "b65035dff9422a66ab9b84c5270960fc"
  "1ac4363043c8ee38995e8fa71e2b3e22",
};

const char *test_plaintexts[] = {
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1" 
};

const char *test_ciphertexts[] = {
  "8fc3a53656b1f778c129df4e9848a41e",
  "524e192f4715c6231f51f6367ea43f18",
  "6cd61bcb190b30384e8a3f168690ae82",
  "688329d019e505041e52e92af95291d4",
  "8f5fbd0510d15fa893fa3fda6e857ec2",
  "c8241816f0d7e48920ad16a1674e5d48"
};

size_t bin2hex(uint8_t *p, char hex[], size_t len);
size_t hex2bin(void *bin, const char hex[]);

int test_set_key(void) {
    RC6_KEY rc6_key;
    size_t  /*plen, clen,*/ klen, koutlen;

    uint8_t k[32];
    uint8_t k_out[RC6_KR];
    uint8_t c_in[32], c_out[32];
    uint8_t p_in[32], p_out[32];

    for (size_t i = 0; i < sizeof(test_keys) / sizeof(char*); i++)
    {
        memset(p_in, 0, sizeof(p_in));
        memset(p_out, 0, sizeof(p_out));
        memset(c_in, 0, sizeof(c_in));
        memset(c_out, 0, sizeof(c_out));
        memset(k, 0, sizeof(k));
        memset(k_out, 0, sizeof(k_out));

        klen = hex2bin(k, test_keys[i]);
        // clen = hex2bin(c_in, test_ciphertexts[i]);
        // plen = hex2bin(p_in, test_plaintexts[i]);

        printf("test_keys[%2ld]: %64s - klen %ld\n", i, test_keys[i], klen);

        printf("Set key ...\n");

        ww_set_key(&rc6_key, k, klen);

        printf("test_keys[%2ld] - content of rc6_key:", i);
        for (size_t j = 0; j < klen; j++)
          printf(" %08" PRIx32, rc6_key.x[j]);
        printf("\n\n");

        printf("test_keys_load[%2ld] - content of rc6_key:", i);
        for (size_t j = 0; j < klen; j++)
          printf(" %.8s", test_keys_load[i] + j * 8);
        printf("\n\n");

        koutlen = hex2bin(k_out, test_keys_load[i]);
        printf("rc6_key.x[0] : %08" PRIx32 "\nk_out[0] : %08" PRIx32 "\n", rc6_key.x[0], k_out[0]);
        assert(memcmp(rc6_key.x, k_out, koutlen) == 0);

        // printf("Encrypt ...\n");

        // ww_encrypt(&rc6_key, p_in, c_out);

        // assert(memcmp(c_in, c_out, clen) == 0);

        // printf("Decrypt ...\n");

        // ww_decrypt(&rc6_key, c_out, p_out);

        // assert(memcmp(p_in, p_out, plen) == 0);
    }

    return (0);
}

int main(void)
{
    test_set_key();
    return (0);
}
