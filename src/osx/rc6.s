%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))
%define RC6_P      0b7e15163h
%define RC6_Q      09e3779b9h

extern  _GLOBAL_OFFSET_TABLE_  ; Each code module in your shared library should define the GOT as an external symbol

global _ww_set_key
global __ww_set_key

; pushad in 64 do not exist
%macro pushad 0
    push   rax
    push   rbx
    push   rsi
    push   rbp
    push   rdi
    push   rdx
%endmacro

; Note: Remember that the call instruction is basically equivalent to
; push eip + SIZE_OF_TWO_INSTRUCTION ; return address is current address + size of two instructions
; jmp _MyFunction

; :    : 
; |  2 | [ebp + 4*DWORD] (3rd function argument)
; |  5 | [ebp + 3*DWORD] (2nd argument)
; | 10 | [ebp + 2*DWORD]  (1st argument)
; | RA | [ebp + DWORD]  (return address)
; | FP | [ebp]      (old ebp value)
; |    | [ebp - DWORD]  (1st local variable)
; :    :
; :    :
; |    | [ebp - X]  (esp - the current stack pointer. The use of push / pop is valid now)

; Reading Without Popping DWORD PTR SS:[esp]

section .text
__ww_set_key:
    push rbp
    mov rbp, rsp
    ; and rsp, 0xfffffff0; Align the stack to allow library calls

; rdx=rc6 key
; rsi=key bytes
; rcx=key len

rc6_setkey:
    push rdi                    ; x86_64 linux/osx machine passes function parameters in rdi, rsi, rdx, rcx, r8, and r9
    push rsi
    push rdx

    pop     rcx                 ; rcx=key len
    pop     rsi                 ; rsi=key bytes
    pop     rdx                 ; rdx=rc6 key

    sub     rsp, rcx            ; Create local buffer of size rcx
    mov     rdi, rsp

                                ; mov eax, 0xA  ; set EAX to 0xA (1010 in binary)
                                ; shr eax, 2    ; shifts 2 bits to the right in EAX, now equal to 0x2 (0010 in binary)
    shr     ecx, 2              ; keylen/= 4
    mov     rbx, rcx            ; save keylen/4

                                ; copy to local buffer
                                ; mov rdi string to rsi string
    rep     movsd               ; rep repeats till rcx is 0

    mov     rax, RC6_P
    mov     rsi, rdx
    mov     rdi, rdx
    mov     rcx, RC6_KR
init_key:
    stosd                       ; stosd stores a doubleword from the EAX register into the destination operand.    
    add     rax, RC6_Q

    loop    init_key            ; Each time loop is executed, the count register is decremented, then checked for 0.

    push    rbp                 ; Save rpb, very very important

    xor    eax, eax             ; A=0
    xor    ebx, ebx             ; B=0
    xor    ebp, ebp             ; k=0
    xor    edi, edi             ; i=0
    xor    edx, edx             ; j=0
    
                                ; mov   eax, 0x5   ; eax = 0x5, SF = 0
                                ; cdq              ; edx = 0x00000000
                                ; mov   eax, 0x5   ; eax = 0x5
                                ; neg   eax        ; eax = 0xFFFFFFFB, SF = 1
                                ; cdq              ; edx = 0xFFFFFFFF
    ; cdq                ; B=0

setkey_loop:                    ; A = key->S[i] = ROTL(key->S[i] + A+B, 3); 
    add    eax, ebx             ; A+B
    add    eax, [rsi + rdi * 4] ; key->S[i] + A+B (eax)
    call debug

    rol    eax, 3               ; rotate 3 bits left in eax
    lea    ecx, [eax + ebx]

    mov    [rsi + rdi * 4], eax

    call debug


                                ; B = L[j] = ROTL(L[j] + A+B, A+B);
    add    ebx, eax
    add    ebx, [rsp+4*rdx+4]
    rol    ebx, cl
    mov    [rsp+4*rdx+4], ebx

    inc    edi          ; i++

    ; i %= (RC6_ROUNDS*2)+4
    cmp    edi, RC6_KR

    sbb    ecx, ecx     ; The sbb edx, edx statement writes either 0 or -1 to edx, depending only on the value of the carry flag. 
    and    edi, ecx

    inc    edx          ; j++

    ; j %= RC6_KEYLEN/4
    cmp    edx, [rsp]
    sbb    ecx, ecx
    and    edx, ecx
    inc    ebp
    cmp    ebp, RC6_KR*3
    jne    setkey_loop
setkey_loop_return:
    pop     rbp         ; retrieve top stack pointeur, that was change during 
    leave               ; mov   rsp, rbp \n pop   rbp
    ret

%define _A esi
%define _B ebx
%define _C edx
%define _D ebp

global _ww_crypt
global __ww_crypt

__ww_crypt:             ; rc6key:dword, input:dword, output:dword, enum: dword
    ; rdi=key
    ; rsi=input
    push rbp
    mov rbp, rsp
rc6_encrypt:
    push rdi            ; x86_64 linux/osx machine passes function parameters in rdi, rsi, rdx, rcx, r8, and r9
    push rsi
    push rdx
    push rcx

    ; edi=rc6 key
    ; esi=input

    ; load cyphertext
    lodsd
    xchg    eax, ecx
    lodsd
    xchg    eax, _B
    lodsd
    xchg    eax, _C
    lodsd
    xchg    eax, _D
    xchg    ecx, _A

    mov     eax, RC6_ROUNDS
    pop     rcx
    push    rcx
    ; mov     ecx, [esp+32+16] ; enc
    jecxz   rc6_l1              ; It jumps to the specified location if ECX=0
    
    ; B += key->x[0];
    add     _B, [edi]
    scasd

    ; D += key->x[1];
    add     _D, [edi]
    jmp     rc6_l2
rc6_l1:
    lea    edi, [edi+ecx*8+12]  ; move to end of key

                                ; load backwards
    std                         ; Operation:1 -> DF
    
    ; C -= key->x[43];
    sub    _C, [edi]
    
    ; A -= key->x[42];
    scasd
    sub    _A, [edi]
    xchg   _D, _A
    xchg   _C, _B
rc6_l2:
    scasd
rc6_l3:
    push   rax
    push   rcx
    dec    rcx
    pushfq
    
    ; T0 = ROTL(B * (2 * B + 1), 5);
    lea    eax, [_B+_B+1]
    imul   eax, _B
    rol    eax, 5
    ; T1 = ROTL(D * (2 * D + 1), 5);
    lea    ecx, [_D+_D+1]
    imul   ecx, _D
    rol    ecx, 5
    popfq
    jnz    rc6_l4

    ; A = ROTL(A ^ T0, T1) + key->x[i];
    xor    _A, eax
    rol    _A, cl
    add    _A, [edi]  ; key->x[i]
    scasd
    ; C = ROTL(C ^ T1, T0) + key->x[i+1];
    xor    _C, ecx
    xchg   eax, ecx
    rol    _C, cl
    add    _C, [edi]  ; key->x[i+1]
    jmp    rc6_l5
rc6_l4:    
    ; B = ROTR(B - key->x[i + 1], t) ^ u;
    sub    _C, [edi]
    scasd
    ror    _C, cl   ; t
    xor    _C, eax  ; u
    ; D = ROTR(D - key->x[i], u) ^ t;
    xchg   eax, ecx ; swap u and t
    sub    _A, [edi]
    ror    _A, cl   ; u
    xor    _A, eax  ; t
rc6_l5:
    scasd
    ; swap
    xchg   _D, eax
    xchg   _C, eax
    xchg   _B, eax
    xchg   _A, eax
    xchg   _D, eax
    ; decrease counter
    pop    rcx
    pop    rax
    dec    rax    ; _I--
    jnz    rc6_l3

    jecxz  rc6_l6
    ; out[0] += key->x[42];
    add    _A, [edi]
    ; out[2] += key->x[43];
    add    _C, [edi+4]
    jmp    rc6_l7
rc6_l6:
    xchg   _D, _A
    xchg   _C, _B
    ; out[3] -= key->x[1];
    sub    _D, [edi]
    ; out[1] -= key->x[0];
    sub    _B, [edi-4]
    cld
    
rc6_l7:
    ; save ciphertext
    mov    edi, [esp+32+12] ; output
    xchg   eax, _A
    stosd
    xchg   eax, _B
    stosd
    xchg   eax, _C
    stosd
    xchg   eax, _D
    stosd

    ; The registers are loaded in the following order: EDI, ESI, EBP, EBX, EDX, ECX
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    pop rdx
    pop rcx

rc6_return:
    ret
    
debug:
    push    rax
    push    rdx
    mov     rax, 0x2000004 ; write
    mov     rdi, 1 ; stdout
    lea     rsi, [rel msg]
    mov     rdx, msg.len
    syscall
    pop     rdx
    pop     rax
    ret     ; pops the last value from the stack, which supposed to be the returning address, and assigned it to IP register

section .data
    default rel
    msg: db "Hello, world!", 10
    .len: equ $-msg