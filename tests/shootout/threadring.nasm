global thread_main
extern printf

%include "cabna/sys/iface.nasm"

%assign amount_tasks 503
%assign count 50_000_000


section .data
  fmtstr: db `%li\n`,0


section .text

proc thread_main:
  thread_main_race

  mov ebx, amount_tasks

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.need], 1
  mov qword [arg1_rdi + task.exec], run
  mov [arg1_rdi + task.arg2], rbx  ; Use this field for ID.
  mov r13, arg1_rdi  ; Remember first, to link with last.

  sub ebx, 1
  mov r12, r13

.loop:
  jmp_ret alloc_task
  mov qword [arg1_rdi + task.need], 1
  mov qword [arg1_rdi + task.exec], run
  mov [arg1_rdi + task.rcvr], r12
  mov qword [arg1_rdi + task.ridx], 1
  mov [arg1_rdi + task.arg2], rbx  ; Use this field for ID.
  mov r12, arg1_rdi
  sub ebx, 1
  jnz .loop

  mov [r13 + task.rcvr], arg1_rdi  ; Link first to last.
  mov qword [r13 + task.ridx], 1

  mov qword [arg1_rdi + task.arg1], count
  mov cet_r14, arg1_rdi
  jmp run




proc run:
  mov arg1_rdi, [cet_r14 + task.arg1]
  sub arg1_rdi, 1
  jc .done

  mov qword [cet_r14 + task.need], 1
  jmp_ret_to supply_retval, exec_avail

.done:
  mov rsi, [cet_r14 + task.arg2]  ; ID
  mov edi, fmtstr
  mov eax, 0
  call printf
  stat call print_stats
  mov edi, 0
  mov eax, 231  ; exit_group syscall number
  syscall
