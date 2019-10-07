global _ww_encrypt

; The .data section is for storing and naming constants.

_ww_encrypt:
    mov     rax, 0x2000004 ; write
    mov     rdi, 1 ; stdout
    lea     rsi, [rel msg]
    mov     rdx, msg.len
    syscall

    mov     rax, 0x2000001 ; exit
    mov     rdi, 0
    syscall
    ret

section .data

msg:    db      "Hello, world!", 10
; Length of `msg`. `$` refers to the address of this constant, so `$ - msg` is the length of message
.len:   equ     $ - msg