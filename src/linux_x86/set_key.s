%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))
%define RC6_P      0b7e15163h
%define RC6_Q      09e3779b9h

struc RC6_KEY
  x resd RC6_KR
endstruc

global _ww_set_key:function

; pushad in 64 do not exist
%macro pushad 0
    push   rbx
    push   rsi
    push   rbp
    push   rdi
    push   rdx
%endmacro

section .text
_ww_set_key:
  
_rc6_setkey:
    pushad
    pop    rsi
    ; rdx=rc6 key
    push   rcx
    pop    rdx
    ; rcx=key len
    push   r8
    pop    rcx
    ; should check key length?
    ; we assume it's multiple of 4
    ; something else would mess up stack
    sub    rsp, rcx
    mov    rdi, rsp
    
    shr    ecx, 2              ; /= 4
    push   rcx                 ; save keylen/4
    ; copy key to local buffer
    rep    movsd

    mov    eax, RC6_P
    push   rdx
    pop    rsi
    push   rdx
    pop    rdi
    push   RC6_KR
    pop    rcx
init_key:
    stosd   ; copies the value in AL, AX or EAX into the location pointed to by EDI
            ; EDI is then incremented (if direction flag is cleared) or decremented (if direction flag is set)
            ; in preparation for storing AX in the next location.
    add    eax, RC6_Q
    loop   init_key
    
    xor    eax, eax    ; A=0
    xor    ebx, ebx    ; B=0
    xor    ebp, ebp    ; k=0
    xor    edi, edi    ; i=0
    xor    edx, edx    ; j=0
    ret

debug:
    mov rax, 1        ; write(
    mov rdi, 1        ;   STDOUT_FILENO,
    mov rsi, msg      ;   "Hello, world!\n",
    mov rdx, 13   ;   sizeof("Hello, world!\n")
    syscall           ; );
    ret

section .data
  msg db "Hello, world!", 13