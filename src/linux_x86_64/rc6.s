%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))
%define RC6_P      0b7e15163h
%define RC6_Q      09e3779b9h

struc RC6_KEY
  x resd RC6_KR
endstruc

extern  _GLOBAL_OFFSET_TABLE_  ; Each code module in your shared library should define the GOT as an external symbol

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

global _ww_set_key:function
global __ww_set_key:function

_ww_set_key:
    push rbp
    mov rbp, rsp
    ; and rsp, 0xfffffff0 ; Align the stack to allow library calls

_rc6_setkey:
rc6_setkey:
    push rdi            ; x86_64 linux/osx machine passes function parameters in rdi, rsi, rdx, rcx, r8, and r9
    push rsi
    push rdx

    pop     rcx         ; rcx=key len
    pop     rsi         ; rsi=key bytes
    pop     rdx         ; rdx=rc6 key

    sub     rsp, rcx    ; Create local buffer of size rcx
    mov     rdi, rsp

                        ; mov eax, 0xA  ; set EAX to 0xA (1010 in binary)
                        ; shr eax, 2    ; shifts 2 bits to the right in EAX, now equal to 0x2 (0010 in binary)
    shr     ecx, 2      ; keylen/= 4
    mov     rbx, rcx    ; save keylen/4

                        ; copy to local buffer
                        ; mov rdi string to rsi string
    rep     movsd       ; rep repeats till rcx is 0

    mov     rax, RC6_P
    mov     rsi, rdx
    mov     rdi, rdx
    mov     rcx, RC6_KR
init_key:
    stosd                ; stosd stores a doubleword from the EAX register into the destination operand.    
    add     rax, RC6_Q

    loop    init_key     ; Each time loop is executed, the count register is decremented, then checked for 0.

    push    rbp          ; Save rpb, very very important

    xor    eax, eax    ; A=0
    xor    ebx, ebx    ; B=0
    xor    ebp, ebp    ; k=0
    xor    edi, edi    ; i=0
    xor    edx, edx    ; j=0
    
                        ; mov   eax, 0x5   ; eax = 0x5, SF = 0
                        ; cdq              ; edx = 0x00000000
                        ; mov   eax, 0x5   ; eax = 0x5
                        ; neg   eax        ; eax = 0xFFFFFFFB, SF = 1
                        ; cdq              ; edx = 0xFFFFFFFF
    ; cdq                ; B=0
    
setkey_loop:
    ; A = key->S[i] = ROTL(key->S[i] + A+B, 3); 

setkey_loop_end:
    pop     rbp         ; retrieve top stack pointeur, that was change during 
                        ; mov   rsp, rbp
    leave               ; pop   rbp
    ret

debug:
    push rbp
    mov rbp, rsp
    mov     rax, 1 ; write
    mov     rdi, 1 ; stdout
    lea     rsi, [rel msg]
    mov     rdx, msg.len
    syscall
    leave
    ret     ; pops the last value from the stack, which supposed to be the returning address, and assigned it to IP register

section .data
    default rel
    msg: db "Hello, world!", 10
    .len: equ $-msg