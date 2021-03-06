global thread_main
extern printf
extern dprintf

%include "cabna/sys/iface.nasm"

%assign count 43


section .data
  fmtstr1: db `fibonacci(%lu) = `,0
  fmtstr2: db `%llu\n`,0


section .text

proc thread_main:  ; (done (fibonacci count))
  thread_main_race

  mov edx, count
  mov esi, fmtstr1
  mov edi, 2  ; stderr
  mov eax, 0
  call dprintf  ; Use dprintf to stderr because it flushes immediately.

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], done
  mov qword [arg1_rdi + task.need], 1
  mov rbx, arg1_rdi

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], fibonacci
  mov qword [arg1_rdi + task.arg1], count
  mov qword [arg1_rdi + task.arg2], amount_threads - 1
  mov [arg1_rdi + task.rcvr], rbx
  mov qword [arg1_rdi + task.ridx], 1
  mov cet_r14, arg1_rdi
  jmp fibonacci


proc done:  ; Print value and exit program.
  mov rsi, [cet_r14 + task.arg1]
  mov edi, fmtstr2
  mov eax, 0
  call printf
  stat call print_stats
  mov edi, 0
  mov eax, 231  ; exit_group syscall number
  syscall




; (define (fibonacci n)
;   (if (< 1 n)
;     (+ (fibonacci (- n 1)) (fibonacci (- n 2)))
;     n))

proc fibonacci:
  mov rbx, [cet_r14 + task.arg1]
  mov r12, [cet_r14 + task.arg2]
.start:
  test rbx, -2
  jz .return
  sub r12, 1
  jc .serial_both

  ; Reuse task struc for the tail-call.
  mov qword [cet_r14 + task.exec], addition
  mov qword [cet_r14 + task.need], 2

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], fibonacci
  sub rbx, 1
  mov [arg1_rdi + task.arg1], rbx
  mov [arg1_rdi + task.arg2], r12
  mov [arg1_rdi + task.rcvr], cet_r14
  mov qword [arg1_rdi + task.ridx], 1
  jmp_ret sched_task  ; arg1_rdi already set

  test r12, r12
  jz .serial_one

  jmp_ret alloc_task
  ; mov qword [arg1_rdi + task.exec], fibonacci
  sub rbx, 1
  ; mov [arg1_rdi + task.arg1], rbx
  ; mov [arg1_rdi + task.arg2], r12
  mov [arg1_rdi + task.rcvr], cet_r14
  mov qword [arg1_rdi + task.ridx], 2
  mov cet_r14, arg1_rdi
  jmp .start

.return:
  mov arg1_rdi, rbx
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail

.serial_both:
  call fibonacci_serial  ; rbx already correct.
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail

.serial_one:
  sub rbx, 1  ; Two less than CET's argument.
  call fibonacci_serial
  mov [cet_r14 + task.arg2], arg1_rdi
  lock sub qword [cet_r14 + task.need], 1
  jz addition
  jmp exec_avail




proc fibonacci_serial:
  test rbx, -2
  jz .return
  sub rbx, 1
  push rbx
  call fibonacci_serial
  pop rbx
  sub rbx, 1
  push arg1_rdi
  call fibonacci_serial
  pop rax
  add arg1_rdi, rax
  ret
.return:
  mov arg1_rdi, rbx
  ret




proc addition:
  mov arg1_rdi, [cet_r14 + task.arg1]
  add arg1_rdi, [cet_r14 + task.arg2]
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail
