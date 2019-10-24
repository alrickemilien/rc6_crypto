#include "rc6.h"

void rc6_crypt (RC6_KEY *key, void *input, void *output, int enc)
{
  rc6_blk *in, *out;
  uint32_t A, B, C, D, T0, T1, i;
  uint32_t *k=(uint32_t*)key->x;
  
  in =(rc6_blk*)input;
  out=(rc6_blk*)output;
  
  // load plaintext/ciphertext
  A=in->v32[0];
  B=in->v32[1];
  C=in->v32[2];
  D=in->v32[3];
  
  if (enc==RC6_ENCRYPT)
  {
    B += *k; k++;
    D += *k; k++;
  } else {
    k += 43;
    C -= *k; k--;
    A -= *k; k--;
  }
  
  for (i=0; i<RC6_ROUNDS; i++)
  {
    if (enc==RC6_ENCRYPT)
    {
      T0 = ROTL32(B * (2 * B + 1), 5);
      T1 = ROTL32(D * (2 * D + 1), 5);
      
      A = ROTL32(A ^ T0, T1) + *k; k++;
      C = ROTL32(C ^ T1, T0) + *k; k++;
      // rotate 32-bits to the left
      T0 = A;
      A  = B;
      B  = C;
      C  = D;
      D  = T0;
    } else {
      T0 = ROTL32(A * (2 * A + 1), 5);
      T1 = ROTL32(C * (2 * C + 1), 5); 
      
      B  = ROTR32(B - *k, T0) ^ T1; k--;
      D  = ROTR32(D - *k, T1) ^ T0; k--;
      // rotate 32-bits to the right
      T0 = D;
      D  = C;
      C  = B;
      B  = A;
      A  = T0;
    }
  }
  
  if (enc==RC6_ENCRYPT)
  {
    A += *k; k++;
    C += *k; k++;
  } else {
    D -= *k; k--;
    B -= *k; k--;
  }
  // save plaintext/ciphertext
  out->v32[0]=A;
  out->v32[1]=B;
  out->v32[2]=C;
  out->v32[3]=D;
}

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

static const char *test_plaintexts[] =
{ "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1",
  "00000000000000000000000000000000",
  "02132435465768798a9bacbdcedfe0f1" };

static const char *test_ciphertexts[] =
{ "8fc3a53656b1f778c129df4e9848a41e",
  "524e192f4715c6231f51f6367ea43f18",
  "6cd61bcb190b30384e8a3f168690ae82",
  "688329d019e505041e52e92af95291d4",
  "8f5fbd0510d15fa893fa3fda6e857ec2",
  "c8241816f0d7e48920ad16a1674e5d48"};

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
    size_t  klen, clen, plen;
    uint8_t p1[32], c1[32], c2[32], k[32];

    for (size_t i = 0; i < sizeof(test_keys) / sizeof(char*); i++)
    {
        memset(k, 0, sizeof(k));
        memset (p1, 0, sizeof (p1));
        memset (c1, 0, sizeof (c1));
        memset (c2, 0, sizeof (c2));

        klen = hex2bin(k, test_keys[i]);
        clen=hex2bin (c1, test_ciphertexts[i]);
        plen=hex2bin (p1, test_plaintexts[i]);

        printf("test_keys[%2ld]: %64s - klen %ld\n", i, test_keys[i], klen);

        printf("Set key ...\n");

        rc6_setkey(&rc6_key, k, klen);

        rc6_crypt(&rc6_key, p1, c2, RC6_ENCRYPT);

        printf("test_keys[%2ld] : ", i);
        for (size_t j = 0; j < clen; j++)
            printf("%02" PRIx8, ((uint8_t*)c2)[j]);
        printf("\n\n");
    }

    return (0);
}