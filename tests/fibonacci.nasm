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

; %ifdef statistics_collection
;   mov rdx, rbx
;   mov esi, fmtstr3
;   mov edi, 2  ; stderr
;   mov eax, 0
;   call dprintf  ; Use dprintf to stderr because it flushes immediately.
; %endif

  test rbx, -2
  jz .return

  ; Reuse task struc for the tail-call.
  mov qword [cet_r14 + task.exec], addition
  mov qword [cet_r14 + task.need], 2

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], fibonacci
  sub rbx, 1
  mov [arg1_rdi + task.arg1], rbx
  mov [arg1_rdi + task.rcvr], cet_r14
  mov qword [arg1_rdi + task.ridx], 1
  jmp_ret sched_task  ; arg1_rdi already set

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], fibonacci
  sub rbx, 1
  mov [arg1_rdi + task.arg1], rbx
  mov [arg1_rdi + task.rcvr], cet_r14
  mov qword [arg1_rdi + task.ridx], 2
  mov cet_r14, arg1_rdi
  jmp fibonacci

.return:
  mov arg1_rdi, rbx
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail




proc addition:
  mov arg1_rdi, [cet_r14 + task.arg1]
  add arg1_rdi, [cet_r14 + task.arg2]
  jmp_ret supply_retval
  jmp_ret_to free_pet, exec_avail
