%define RC6_ROUNDS 20
%define RC6_KR     (2*(RC6_ROUNDS+2))
%define RC6_P      0b7e15163h
%define RC6_Q      09e3779b9h

struc RC6_KEY
  x resd RC6_KR
endstruc

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
_rc6_setkey:
    ; x86_64 bit linux/osx machine passes function parameters in rdi, rsi, rdx, rcx, r8, and r9
    ; call .debug
    mov rdx, rdi
    mov rcx, rcx

    mov rax, 0x2000004 ; write
    mov rdi, 1 ; stdout
    mov rdx, rcx
    syscall
    leave
    ret

.debug:
    push rax
    push rdx
    mov     rax, 0x2000004 ; write
    mov     rdi, 1 ; stdout
    lea     rsi, [rel msg]
    mov     rdx, msg.len
    syscall
    pop rdx
    pop rax
    ret     ; pops the last value from the stack, which supposed to be the returning address, and assigned it to IP register

section .data
    default rel
    msg: db "Hello, world!", 10
    .len: equ $-msg