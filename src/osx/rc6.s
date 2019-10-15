%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))
%define RC6_P      0b7e15163h
%define RC6_Q      09e3779b9h

extern  _GLOBAL_OFFSET_TABLE_  ; Each code module in your shared library should define the GOT as an external symbol

global _ww_set_key
global __ww_set_key

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
__ww_set_key:                   ; function prolog
    enter   	8, 0            ; push rbp, THEN mov rbp, rsp, THEN sub rsp, 8 for osx stack alignment
rc6_setkey:                     ;global __ww_set_key:function
    push    rdi                 ; x86_64 linux/osx machine passes function parameters in RDI, RSI, RDX, RCX, R8, and R9
    push    rsi
    push    rdx

    pop     rcx                 ; RCX=key len
    pop     rsi                 ; RSI=key bytes
    pop     rdx                 ; RDX=rc6 key
    push    rbp                 ; <============================= ICI

brkp1:
    push    rcx
    sub     rsp, rcx            ; Create local buffer of size RCX
;     mov     rdi, rsp
;                                 ; mov eax, 0xA  ; set EAX to 0xA (1010 in binary)
;                                 ; shr eax, 2    ; shifts 2 bits to the right in EAX, now equal to 0x2 (0010 in binary)
;     shr     ecx, 2              ; keylen/= 4
;     mov     ebx, ecx            ; save keylen/4 into EBX
;                                 ; copy to local buffer
;                                 ; mov rsi string to rdi string
;     rep     movsd               ; rep repeats till RCX is 0
    
;     mov     eax, RC6_P
;     mov     rsi, rdx            ; Use x86_64 registers over x86 because we are working with adresses
;     mov     rdi, rdx
;     mov     cl, RC6_KR
; init_key:
;     stosd                       ; stosd stores a doubleword from the EAX register into the ESI operand.
;     add     eax, RC6_Q
;     loop    init_key            ; Each time loop is executed, the count register is decremented, then checked for 0.
    
;     ; xor    rdi, rdi             ; RDI=i=0
;     ; xor    rbp, rbp             ; RBP=j=0
;     ; xor    eax, eax             ; EAX=A=0
;     ; xor    edx, edx             ; EDX=B=0
    
;     mov    ch, (-RC6_KR*3) & 255
; setkey_loop:
;     add    eax, ebx                 ; A=A+B
;     ; add    eax, [rsi + rdi * 4]     ; A=A+key->S[i]
;     rol    eax, 3                   ; rotate 3 bits left in EAX
;     ; mov    [rsi + rdi * 4], eax     ; key->S[i]=A
    
; brkp2:
;                                     ; B = L[j] = ROTL(L[j] + A+B, A+B);
;     add    edx, eax                 ; B=B+A
;     mov    cl, dl                   ; Stroe A+B in cl
;     ; add    edx, [rsp + 4 + 4 * rbp]     ; B=B+L[j]
;     rol    edx, cl                  ; B=ROTL(B, A+B)
;     ; mov    [rsp + 4 + 4 * rbp], edx     ; L[j]=B

;     inc    edi                      ; i++
;                                     ; i %= (RC6_ROUNDS*2)+4

;     cmp    edi, RC6_KR              ; Store cmp value beteween EDI and RC6_KR
setkey_loop_return:
    pop     rcx
    add     rsp, rcx
    pop     rbp
    call debug

    leave                           ; mov   rsp, rbp \n pop   rbp

    ret

debug:                     ; All those push and pop prevents from other register modification side effect
    enter   8, 0 
    push    rbx
    push    rcx
    push    rdi
    push    rsi
    push    rax
    push    rdx
    mov     rax, 0x2000004  ; write
    mov     rdi, 1          ; stdout
    lea     rsi, [rel msg]
    mov     rdx, msg.len
    syscall
    pop     rdx
    pop     rax
    pop     rsi
    pop     rdi
    pop     rcx
    pop     rbx    
    leave
    ret                     ; pops the last value from the stack, which supposed to be the returning address, and assigned it to IP register

section .data
    default rel
    msg: db "Hello, world!", 10
    .len: equ $-msg
