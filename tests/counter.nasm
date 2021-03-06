global _start
global thread_main

%include "cabna/sys/iface.nasm"

%assign count 100_000_000


section .text

def_start

proc thread_main:  ; (done (a n))
  thread_main_race

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], done
  mov qword [arg1_rdi + task.need], 1
  mov rbx, arg1_rdi

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], a
  mov qword [arg1_rdi + task.arg1], count
  mov [arg1_rdi + task.rcvr], rbx
  mov qword [arg1_rdi + task.ridx], 1
  mov cet_r14, arg1_rdi
  jmp a


proc done:  ; Exit program.
  stat call print_stats
  mov rdi, [cet_r14 + task.arg1]
  mov eax, 231  ; exit_group syscall number
  syscall



; (define (a n) (b (- n 1)))
proc a:
  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], b

  mov rax, [cet_r14 + task.arg1]
  sub rax, 1
  mov [arg1_rdi + task.arg1], rax

  mov rax, [cet_r14 + task.rcvr]
  mov [arg1_rdi + task.rcvr], rax
  mov rax, [cet_r14 + task.ridx]
  mov [arg1_rdi + task.ridx], rax

  jmp_ret free_pet
  mov cet_r14, arg1_rdi
  jmp b



; (define (b n) (c (- n 2)))
proc b:
  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], c

  mov rax, [cet_r14 + task.arg1]
  sub rax, 2
  mov [arg1_rdi + task.arg1], rax

  mov rax, [cet_r14 + task.rcvr]
  mov [arg1_rdi + task.rcvr], rax
  mov rax, [cet_r14 + task.ridx]
  mov [arg1_rdi + task.ridx], rax

  jmp_ret free_pet
  mov cet_r14, arg1_rdi
  jmp c



; (define (c n) (if (<= n 0) n (a n)))
proc c:
  mov rbx, [cet_r14 + task.arg1]
  test rbx, rbx
  likely jg .continue
  mov arg1_rdi, rbx
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail

.continue:
  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], a

  mov [arg1_rdi + task.arg1], rbx

  mov rax, [cet_r14 + task.rcvr]
  mov [arg1_rdi + task.rcvr], rax
  mov rax, [cet_r14 + task.ridx]
  mov [arg1_rdi + task.ridx], rax

  jmp_ret free_pet
  mov cet_r14, arg1_rdi
  jmp a
