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
  sub qword [cet_r14 + task.arg1], 1
  mov qword [cet_r14 + task.exec], b
  jmp b



; (define (b n) (c (- n 2)))
proc b:
  sub qword [cet_r14 + task.arg1], 2
  mov qword [cet_r14 + task.exec], c
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
  mov qword [cet_r14 + task.exec], a
  jmp a
