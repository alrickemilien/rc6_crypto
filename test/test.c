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

static const char *test_keys[] = {
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

static const char *test_keys_load[] = {
  "1c31662a2d85179b07b208818541d139"
  "5fdf649ccd6bed4b2687d8b1c6e86e4e"
  "9cfaf76624279c42bfb655c99ae40693"
  "d94d52753cdaf4569b6bc05e9b77bcab"
  "a139ee155f75e7668d06250060d7b67c"
  "bea4b4a6b88fb9119f012b51ce9f195a"
  "9e8f46bd3a6db61d90d3b56142edbf84"
  "e8ae9086e59e4b77b134d59fe0398984"
  "5637a062497397fdcacdab59911eafc8"
  "07216d8e7d2c9b3504800163e37ab2c7"
  "b3c1fc55b78dbdc56a01b40583ac384b",

  "389d470582e5a3e44b7accfba4fa78e8"
  "8049d18efd73585fe65ac0ae1dfeffaa"
  "e3b7f86b8276e2646fd4c4234b1c52da"
  "92932b6671e91ac57a5884be81143c47"
  "846624ab470077b96a7b329829e29b52"
  "9a8092b956fac1798dd17c61089acb1b"
  "b3bbab8bbd61d00da2c81e8cd086f220"
  "f4eff8fa927cb846016b09c5b0c9dcdb"
  "b412b2d1383d0fddf32dc0272615b20f"
  "a6fae0468f74d9e9ccfd74e28e3fae09"
  "405ef895400af9a96914e5f0d160f045",

  "e8343f481f4bffbe7b22d3ccc24ef965"
  "edfc0174d9130acacb543691d31fb91a"
  "6090b1df7a522d82cc8117be5f6de1c4"
  "b14e63614dbc19a4e7486a2fd66cb121"
  "76c1343f76faa66f7ab2901d2a5314cc"
  "8f128923c388d00488582c12ac325111"
  "39c57f9f1bb139b76f1f0874e5748afb"
  "764e6a444e9cdbbcedab79e8584a07fa"
  "bc01ab2e641526f15a7ee3516cb315c8"
  "2ede7b45359782828d83d4b1f71746cc"
  "6e5946f3975eb68747b07a226f644660",

  "de0ad804a39652c83c85cac7a0be65d6"
  "2f49344d65bf10e183cf4a9f10cb85eb"
  "ebf8f0f93fea75221487dce5b4b8b4a1"
  "0acd281a87be8f61e0edc16f4d63af8e"
  "0139217d73abd7be2e09ba798abc7961"
  "f6b635aacab39100e970f965949e7e68"
  "88517ef1f75cc57e938e2cfeae3d7b2e"
  "b83c095603fa28edecaa2eab6f3649d0"
  "d3cbd4fc6f90b384f1d9ce8e53242ae0"
  "036e3b12812a19a62c25488604bd9fb2"
  "c12d5d73587b4497b2462b364203317c",

  "1b1be0652e2080b50ecced584fe5fd03"
  "f9eae160802780f2df7bed0b69e17cb7"
  "69653ceb74b8ee8ca8300febafb3759d"
  "d8bf9ca6fa6c0cbfc5b9ff475a201239"
  "d8844502395999cd6a6a6853c9cd3fd0"
  "13f50e2326ec1f91ab733277ac5784ce"
  "d3e275cced1a70423342498c7a6ce826"
  "d8bd681db3866d38797102ab11002ea2"
  "2586122bae7c008f7269df83e4995721"
  "284fcf82ffcfcc269def5a52ac977484"
  "49625223a81b73fea74b8a3bd69b5f5d",

  "34ee4e8d9d55a36c454dc7ca4a870ac0"
  "f94e035ff4bcffe5d7de57eed7600112"
  "386dd319b5f8924203b2cf60e27cadd5"
  "953e045eb0e922793423eea1aa87679c"
  "0923cb215e83cdc6ba685ff615a5747c"
  "35939e24da27d39e603ed56c131a0a3e"
  "df3550b6662a42f9c5849babfc600927"
  "3036c41a38eec843a78f5e99223e2b1e"
  "932de54c09a9c99c847976247dd18aef"
  "91d552c26233bfa8868f15008609e8ca"
  "d0cf67b2132b571d4bc817bd15dc21a2",
};

static const char *test_plaintexts[] = {
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1" 
};

static const char *test_ciphertexts[] = {
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
    size_t  /*plen, clen,*/ klen;

    uint8_t k[32];
    uint8_t k_out[RC6_KR * sizeof(uint32_t)];
    uint8_t c_in[32], c_out[32];
    uint8_t p_in[32], p_out[32];

    (void)test_plaintexts;
    (void)test_ciphertexts;

    for (size_t i = 0; i < sizeof(test_keys) / sizeof(char*) ; i++)
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

        // printf("test_keys[%2ld] - content of rc6_key:", i);
        // for (size_t j = 0; j < RC6_KR* sizeof(uint32_t); j++)
        //     printf("%02" PRIx8, ((uint8_t*)rc6_key.x)[j]);
        // printf("\n\n");
        // printf("test_keys_load[%2ld] - content of k_out:", i);
        // for (size_t j = 0; j < RC6_KR* sizeof(uint32_t); j++)
        //     printf("%02" PRIx8, ((uint8_t*)k_out)[j]);
        // printf("\n\n");

        hex2bin(k_out, test_keys_load[i]);

        assert(memcmp(rc6_key.x, k_out, RC6_KR * sizeof(uint32_t)) == 0);

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
