The projects implements symmetric encrypt / decrypt functions with algorithm built through asm, for discovering purposes

- Encryption must use external or self generated key.
- Decryption execution must be insignificant.
- Crypto functions must work for big and little endian.
- Crypto functions must work on i384 and x64.

The possible implementation are the following :

- [Brian Gladman's AES algorithms](https://github.com/BrianGladman/aes)
- [XTEA algorithm](https://en.wikipedia.org/wiki/XTEA)
- [Caesar cipher encryption algorithm](https://medium.com/@maneeshap/caesar-cipher-encryption-algorithm-using-assembly-7699f5ab73c)
- RC6 [here](https://tinycrypt.wordpress.com/2015/12/15/rc6-block-cipher/) and [here](https://modexp.wordpress.com/2018/02/04/arm-crypto/)
- Very basic [shit](https://www.codeproject.com/Articles/264491/Huo-Encryption-Decryption-Assembly-Program) but nice for introduction, use no key
- [Blowfish](http://www.unige.ch/medecine/nouspikel/ti99/blowfish.htm)
- [Polymorphic engines](https://www.pelock.com/articles/polymorphic-encryption-algorithms) encryption algorithms

Keywords:

- Cipher: algorithm for performing encryption or decryption—a series of well-defined steps that can be followed as a procedure.
- AES: [Advanced Encryption Standard](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard#Definitive_standards), is a specification for the encryption
- Block cipher: deterministic algorithm operating on fixed-length groups of bits, called blocks, with an unvarying transformation that is specified by a symmetric key.
- There are two basic types of Encryption
    Symmetric. It uses same key for encryption and Decryption.
    Asymmetric. It uses two different keys(public and private) to encrypt and decrypt.

We decide here to implement **RC6** algorithm.

## Build

Build requires **nasm 2.14**. Actually build works only on osx.
Build generates `libww_crypto.so` into `./build` directory.

## Test

During compilation, binary test is provided at `./build/test`.

On OSX, just run `./build/test`
On Linux platform, run `LD_LIBRARY_PATH=build/ ./build/test`

