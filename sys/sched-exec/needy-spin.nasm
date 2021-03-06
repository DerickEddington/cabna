bits 64
default rel


%include "cabna/sys/conv.nasm"


global sched_task
global exec_avail




section .text


proc sched_task:
  ; Push a task in the thread's private executable-tasks stack; or if another
  ; thread needs a task, try to give the task to the needy thread.  Argument in
  ; arg1_rdi, and return to ret_rsi.
  ; Used registers: rax, rsi, rdi.

  stat add qword [tds_r15d + thread.sched_calls], 1

  ; Check if another thread needs a task.
  mov eax, [needy]
  test eax, eax
  jnz .give

.in_mine:
  mov rax, [tds_r15d + thread.executables]
  mov [arg1_rdi + task.next], rax
  mov [tds_r15d + thread.executables], arg1_rdi
%ifdef statistics_collection
  add qword [tds_r15d + thread.sched_mine], 1
  mov rax, [tds_r15d + thread.exec_s_size]
  add rax, 1
  mov [tds_r15d + thread.exec_s_size], rax
  cmp rax, [tds_r15d + thread.exec_s_max]
  jbe .not_max
  mov [tds_r15d + thread.exec_s_max], rax
.not_max:
%endif
  jmp_ind ret_rsi

.give:
  xor eax, eax
  xchg [needy], eax  ; Locking automatically done for xchg.
  test eax, eax
  unlikely jz .in_mine
  mov [eax + thread.gift], arg1_rdi
  jmp_ind ret_rsi




proc exec_avail:
  ; Pop a task from the thread's private executable-tasks stack, or indicate
  ; that the thread needs a task and wait for one, then execute the task with
  ; cet_r14 set to the task.
  ; Used registers: rax, r14.

  stat add qword [tds_r15d + thread.execute_calls], 1

  mov cet_r14, [tds_r15d + thread.executables]
  test cet_r14, cet_r14
  jz .empty

  ; The next, which might be null, becomes the head.
  mov rax, [cet_r14 + task.next]
  mov [tds_r15d + thread.executables], rax
  mov qword [cet_r14 + task.next], 0

  stat sub qword [tds_r15d + thread.exec_s_size], 1
  stat add qword [tds_r15d + thread.executed_mine], 1

  ; Execute the task's instructions.  Tasks are responsible for giving control
  ; back to exec_evail.
  jmp_ind [cet_r14 + task.exec]

.empty:
  pause
  mov eax, [needy]
  test eax, eax
  unlikely jnz .empty
  lock cmpxchg [needy], tds_r15d
  unlikely jne .empty
.wait:
  pause
  mov cet_r14, [tds_r15d + thread.gift]
  test cet_r14, cet_r14
  jz .wait
  mov [tds_r15d + thread.gift], rax  ; rax is null.
  stat add qword [tds_r15d + thread.needy], 1
  ; Execute the task's instructions.  Tasks are responsible for giving control
  ; back to exec_evail.
  jmp_ind [cet_r14 + task.exec]




section .data  align=128

; The global variable for indicating what thread needs a task.
needy: dd 0
