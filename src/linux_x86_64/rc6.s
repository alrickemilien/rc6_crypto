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
    push rbp
    mov rbp, rsp
    ; and rsp, 0xfffffff0 ; Align the stack to allow library calls

rc6_setkey:                     ; void*,void*,uint32_t
    push    rdi                 ; x86_64 linux/osx machine passes function parameters in rdi, rsi, rdx, rcx, r8, and r9
    push    rsi
    push    rdx

    pop     rcx                 ; rcx=key len
    pop     rsi                 ; rsi=key bytes
    pop     rdx                 ; rdx=rc6 key

    call debug

    sub     rsp, rcx            ; Create local buffer of size rcx
    mov     rdi, rsp

                                ; mov eax, 0xA  ; set EAX to 0xA (1010 in binary)
                                ; shr eax, 2    ; shifts 2 bits to the right in EAX, now equal to 0x2 (0010 in binary)
    shr     ecx, 2              ; keylen/= 4
    mov     ebx, ecx            ; save keylen/4 into ebx

                                ; copy to local buffer
                                ; mov rsi string to rdi string
    rep     movsd               ; rep repeats till rcx is 0

    mov     eax, RC6_P
    mov     esi, edx
    mov     edi, edx
    mov     cl, RC6_KR
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

; setkey_loop:                    ; A = key->S[i] = ROTL(key->S[i] + A+B, 3); 
;     add    eax, ebx             ; A+B
;     add    eax, [rsi + rdi * 4] ; key->S[i] + A+B (eax)
;     call debug

;     rol    eax, 3               ; rotate 3 bits left in eax
;     lea    ecx, [eax + ebx]

;     mov    [rsi + rdi * 4], eax

;     call debug


;                                 ; B = L[j] = ROTL(L[j] + A+B, A+B);
;     add    ebx, eax
;     add    ebx, [rsp+4*rdx+4]
;     rol    ebx, cl
;     mov    [rsp+4*rdx+4], ebx

;     inc    edi          ; i++

;     ; i %= (RC6_ROUNDS*2)+4
;     cmp    edi, RC6_KR

;     sbb    ecx, ecx     ; The sbb edx, edx statement writes either 0 or -1 to edx, depending only on the value of the carry flag. 
;     and    edi, ecx

;     inc    edx          ; j++

;     ; j %= RC6_KEYLEN/4
;     cmp    edx, [rsp]
;     sbb    ecx, ecx
;     and    edx, ecx
;     inc    ebp
;     cmp    ebp, RC6_KR*3
;     jne    setkey_loop
setkey_loop_return:
    pop     rbp         ; retrieve top stack pointeur, that was change during 
    leave               ; mov   rsp, rbp \n pop   rbp
    ret

debug:                     ; All those push and pop prevents from other register modification side effect
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    rcx
    push    rdi
    push    rsi
    push    rax
    push    rdx
    mov     rax, 1          ; write
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
    ret

section .data
    default rel
    msg: db "Hello, world!!!!!!!!", 10
    .len: equ $-msg
