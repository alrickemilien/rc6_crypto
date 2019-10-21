%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))
%define RC6_P      0b7e15163h
%define RC6_Q      09e3779b9h

extern  _GLOBAL_OFFSET_TABLE_  ; Each code module in your shared library should define the GOT as an external symbol

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

global _ww_set_key:function
global __ww_set_key:function

_ww_set_key:
    push    rbp                 ; function prolog
    mov     rbp, rsp
sk:                             ; STACKINFO: rbp
    push    rdi                 ; x86_64 linux/osx machine passes function parameters in RDI, RSI, RDX, RCX, R8, and R9
    push    rsi
    push    rdx

                                ; STACKINFO: rbp, rdi, rsi, rdx

    pop     rcx                 ; RCX=key len
    pop     rsi                 ; RSI=key bytes
    pop     rdx                 ; RDX=rc6 key

                                ; STACKINFO: rbp

    sub     rsp, rcx            ; Create local buffer of size RCX
    mov     rdi, rsp

    push    rcx                 ; Save RCX on the stack, later acces must have start with RSP+8

                                ; mov eax, 0xA  ; set EAX to 0xA (1010 in binary)
                                ; shr eax, 2    ; shifts 2 bits to the right in EAX, now equal to 0x2 (0010 in binary)
    shr     ecx, 2              ; keylen/= 4

                                ; STACKINFO: rcx
                        
    rep     movsd               ; rep repeats till RCX is 0
    
    mov     eax, RC6_P
    mov     rsi, rdx            ; Use x86_64 registers over x86 because we are working with adresses
    mov     rdi, rdx
    mov     rcx, RC6_KR
sk_init:
    stosd                       ; stosd stores a doubleword from the EAX register into the ESI operand.
    add     eax, RC6_Q
    loop    sk_init             ; Each time loop is executed, the RCX is decremented, then checked for 0.

    xor     eax, eax            ; EAX=A=0
    xor     ebx, ebx            ; EBX=B=0
    xor     ebp, ebp            ; EBP=k=0
    xor     edi, edi            ; EDI=i=0
    xor     edx, edx            ; EDX=j=0

    ; mov    ch, (-RC6_KR*3) & 255
sk_l1:
    add    eax, ebx                 ; A=A+B
    add    eax, [rsi + rdi * 4]     ; A=A+key->S[i]
    rol    eax, 3                   ; rotate 3 bits left in EAX
    lea    ecx, [eax + ebx]         ; store A+B into ECX
    mov    [rsi + rdi * 4], eax     ; key->S[i]=A
    
                                    ; B = L[j] = ROTL(L[j] + A+B, A+B);
    add    ebx, eax                 ; B=B+A
    add    ebx, [rsp + 4 + rbp * 4] ; B=B+L[j]
    rol    ebx, cl                  ; B=ROTL(B, A+B) cl is the part of ecx where is stored A+B
    mov    [rsp + 4 + rbp * 4], ebx ; L[j]=B
    
    inc    edi                      ; i++

                                    ; i %= (RC6_ROUNDS*2)+4
    cmp    edi, RC6_KR  
    sbb    ecx, ecx                 ; Adds second operand and the CF flag,
                                    ; then subtracts the result from first operand.
                                    ; Result of the subtraction is stored in the second operand. 
    and    edi, ecx

    ; j++
    inc    edx       
    
    ; j %= RC6_KEYLEN/4
    cmp    edx, [rsp]
    sbb    ecx, ecx
    and    edx, ecx
    inc    ebp
    cmp    ebp, RC6_KR*3
    jne    sk_l1

    ; STACKINFO: rbp, rcx/4
      
    pop    rcx
    add    rsp, rcx
    
    leave
    ret

%define A esi
%define B ebx
%define C edx
%define D ebp

global _ww_crypt:function
global __ww_crypt:function

_ww_crypt:
    push rbp        ; function prolog
    mov rbp, rsp

    ; rdi => rc6_key
    ; rsi => input
    ; rdx => output
    ; rcx => encrypt/decrypt mode
crypt:                          ; x86_64 parameters order is RDI, RSI, RDX, RCX, R8, and R9
    push    rdx                 ; output
    push    rcx                 ; encrypt/decrypt mode
    push    rsi                 ; input
    push    rdi                 ; rc6_key
    push    rbp                 ; Save RBP because now it is used for D
load_ciphertext:
    lodsd                       ; loadsd load doubleword at address DS:(E)SI into EAX
    xchg   eax, D
    lodsd
    xchg   eax, B
    lodsd
    xchg   eax, C
    lodsd
    xchg   eax, D
    xchg   eax, A
crypt_l0:
    mov    eax, RC6_ROUNDS
    mov    ecx, [rsp + 8 * 3]   ; Get the encrypt/decrypt mode access pshed rcx
    jecxz  crypt_l1

    add    B, [rdi]             ; B += key->x[0];
    scasd                       ; compares doubleword using ES:(E)DI register with the value in EAX, then sets status flags in EFLAGS

    add    D, [rdi]             ; D += key->x[1];
    jmp    crypt_l2
crypt_l1:
    lea    edi, [rdi + rax * 8 + 12]    ; move to end of key
    std                                 ; load backwards
    
    sub    C, [rdi]                     ; C -= key->x[43];

    scasd                               ; compares doubleword using ES:(E)DI register with the value in EAX, then sets status flags in EFLAGS
    sub    A, [rdi]                     ; A -= key->x[42];
    xchg   D, A
    xchg   C, B
crypt_l2:
    scasd
crypt_l3:
    push    rax
    push    rcx
    dec     rcx
    
    push    rax
    push    rcx
    push    rdx
    push    rbx
    push    rsp
    push    rbp
    push    rsi
    push    rdi
    
                            ; T0 = ROTL(B * (2 * B + 1), 5);
    lea     eax, [B+B+1]    ; T0=2*B+1
    imul    eax, B          ; T0=B*TO
    rol     eax, 5          ; T0=ROTL(T0, 5)
    
                            ; T1 = ROTL(D * (2 * D + 1), 5);
    lea     ecx, [D+D+1]    ;
    imul    ecx, D          ;
    rol     ecx, 5          ;
    pop     rdi
    pop     rsi
    pop     rbp
    pop     rsp
    pop     rbx
    pop     rdx
    pop     rcx
    pop     rax

    jnz    crypt_l4

                        ; A = ROTL(A ^ T0, T1) + key->x[i];
    xor    A, eax       ; A=A^T0
    rol    A, cl        ; A=ROTL(A)
    add    A, [rdi]     ; A=A+key->x[i]
    scasd
    
                        ; C=ROTL(C ^ T1, T0) + key->x[i+1];
    xor    C, ecx       ; C=C^T1
    xchg   eax, ecx     ; switch T0 and T1
    rol    C, cl        ; C=ROTL(C, T0)
    add    C, [rdi]     ; C=C+key->x[i+1]
    
    jmp    crypt_l5
crypt_l4:    
                        ; B = ROTR(B - key->x[i + 1], t) ^ u;
    sub    C, [edi]
    scasd
    ror    C, cl        ; t
    xor    C, eax       ; u
    
                        ; D = ROTR(D - key->x[i], u) ^ t;
    xchg   eax, ecx     ; swap u and t
    sub    A, [edi]
    ror    A, cl        ; u
    xor    A, eax       ; t
crypt_l5:
    scasd
    
    ; swap
    xchg   D, eax
    xchg   C, eax
    xchg   B, eax
    xchg   A, eax
    xchg   D, eax
    
    ; decrease counter
    pop    rcx
    pop    rax
    dec    eax          ; _I--
    
    jnz    crypt_l3

    jecxz  crypt_l6
    
    add    A, [rdi]     ; out[0] += key->x[42];
    add    C, [rdi+4]   ; out[2] += key->x[43];
    jmp    crypt_l7
crypt_l6:
    xchg   D, A
    xchg   C, B
    sub    D, [rdi]     ; out[3] -= key->x[1];
    sub    B, [rdi-4]   ; out[1] -= key->x[0];
    cld
crypt_l7:                   ; save ciphertext
    ; mov    edi, [esp+32+12] ; output
    xchg   eax, A
    stosd
    xchg   eax, B
    stosd
    xchg   eax, C
    stosd
    xchg   eax, D
    stosd
    ; popad
crypt_return:
    pop     rbp
    pop     rdi
    pop     rsi
    pop     rcx
    pop     rdx

    leave           ; mov   rsp, rbp \n pop   rbp
    ret

section .data
    default rel
