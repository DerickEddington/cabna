bits 64
default rel


%include "cabna/sys/conv.nasm"


global notify_receiver
global supply_retval

extern sched_task




section .text


proc notify_receiver:
  ; Notify the currently executing task's waiting receiver task that one of its
  ; tasks finished.  If the receiver task gets its final notice, schedule the
  ; task for execution.  Return to ret_rsi.
  ; Used registers: rsi, rdi, and those of sched_task.

  ; No other threads will access our currently executing task struc, so we can
  ; access it without concurrency concern.
  mov arg1_rdi, [cet_r14 + task.rcvr]
  ; Other threads will access the .need field, so we must atomically decrement
  ; it.
  lock sub dword [arg1_rdi + task.need], 1  ; 32-bit alright.
  ; Supplied the final needed argument to rcvr, so schedule rcvr for execution.
  jz sched_task  ; arg1_rdi and ret_rsi are already set.
  ; Receiver needs more.
  jmp_ind ret_rsi




proc supply_retval:
  ; Return a value to the currently executing task's waiting receiver task,
  ; argument in arg1_rdi.  If the receiver task gets its final value, schedule
  ; the task for execution.  Return to ret_rsi.
  ; Used registers: rax, rdx, rsi, rdi, and those of sched_task.

  ; No other threads will access our currently executing task struc, so we can
  ; access it without concurrency concern.
  mov rax, [cet_r14 + task.rcvr]
  mov edx, [cet_r14 + task.ridx]  ; 32-bit alright.
  ; No other threads will access this field in rcvr, so we can access it without
  ; concurrency concern.
  mov [rax + task.args + 8 * rdx], arg1_rdi
  ; Other threads will access the .need field, so we must atomically decrement
  ; it.
  lock sub dword [rax + task.need], 1  ; 32-bit alright.
  cmovz arg1_rdi, rax  ; For sched_task.
  ; Supplied the final needed argument to rcvr, so schedule rcvr for execution.
  jz sched_task  ; ret_rsi already set.
  ; Receiver needs more.
  jmp_ind ret_rsi
