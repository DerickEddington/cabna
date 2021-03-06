global thread_main
extern printf
extern dprintf

%include "cabna/sys/iface.nasm"

%assign count 1_000_000_000


section .data
  fmtstr1: db `summation(%ld, %ld) = `,0
  fmtstr2: db `%ld\n`,0


section .text

proc thread_main:  ; (done (summation 1 count))
  thread_main_race

  mov rcx, count
  mov edx, 1
  mov esi, fmtstr1
  mov edi, 2  ; stderr
  mov eax, 0
  call dprintf  ; Use dprintf to stderr because it flushes immediately.

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], done
  mov qword [arg1_rdi + task.need], 1
  mov rbx, arg1_rdi

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], summation
  mov qword [arg1_rdi + task.arg1], 1
  mov rax, count
  mov qword [arg1_rdi + task.arg2], rax
  mov qword [arg1_rdi + task.arg3], amount_threads - 1
  mov [arg1_rdi + task.rcvr], rbx
  mov qword [arg1_rdi + task.ridx], 1
  mov cet_r14, arg1_rdi
  jmp summation


proc done:  ; Print value and exit program.
  mov rsi, [cet_r14 + task.arg1]
  mov edi, fmtstr2
  mov eax, 0
  call printf
  stat call print_stats
  mov edi, 0
  mov eax, 231  ; exit_group syscall number
  syscall




; (define (summation s e)
;   (cond ((>= s e)       s)
;         ((= s (- e 1))  (+ s e))
;         (else           (let ((x (floor (/ (+ s e) 2))))
;                           (+ (summation s x) (summation (+ 1 x) e))))))

proc summation:
  mov arg1_rdi, [cet_r14 + task.arg1]
  mov r13, [cet_r14 + task.arg2]
  mov rbx, r13

  sub rbx, arg1_rdi
  jg .continue_1
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail

.continue_1:
  test rbx, -2
  jnz .continue_2
  add arg1_rdi, r13
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail

.continue_2:
  ; TODO: Use arg3 and divide work for threads.

  ; Reuse task struc for the tail-call.
  mov qword [cet_r14 + task.exec], addition
  mov qword [cet_r14 + task.need], 2

  shr rbx, 1  ; Divide difference by two.
  mov r12, arg1_rdi

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], summation
  mov qword [arg1_rdi + task.arg1], r12
  add rbx, r12
  mov qword [arg1_rdi + task.arg2], rbx
  mov [arg1_rdi + task.rcvr], cet_r14
  mov qword [arg1_rdi + task.ridx], 1
  jmp_ret sched_task  ; arg1_rdi already set

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], summation
  add rbx, 1
  mov qword [arg1_rdi + task.arg1], rbx
  mov qword [arg1_rdi + task.arg2], r13
  mov [arg1_rdi + task.rcvr], cet_r14
  mov qword [arg1_rdi + task.ridx], 2
  mov cet_r14, arg1_rdi
  jmp summation




proc addition:
  mov arg1_rdi, [cet_r14 + task.arg1]
  add arg1_rdi, [cet_r14 + task.arg2]
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail
