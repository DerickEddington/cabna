global _start
global thread_main

%include "cabna/sys/iface.nasm"

%assign array_size   (16 << 20)
%assign file_length  (8 * array_size)


section .data
  file_name: db `tests/random-array-16M--cabna`,0
  array_ptr: dq 0
  errmsg: db `Initialization failed.\n`,0
  errmsg_size  equ  $ - errmsg


section .text

def_start

proc thread_main:
  thread_main_race

  mov esi, 2  ; O_RDWR
  mov edi, file_name
  mov eax, 2  ; open syscall number.
  syscall
  cmp rax, -4096
  ja .error

  xor r9d, r9d          ; pgoffset
  mov r8, rax           ; fd
  mov r10d, 1           ; flags = MAP_SHARED
  mov edx, 3            ; prot = PROT_READ | PROT_WRITE
  mov rsi, file_length  ; length
  xor edi, edi          ; addr = NULL
  mov eax, 9            ; mmap syscall number
  syscall
  cmp rax, -4096
  ja .error
  mov [array_ptr], rax

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], done
  mov dword [arg1_rdi + task.need], 1
  mov r12, arg1_rdi

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], quicksort
  mov qword [arg1_rdi + task.arg1], 0
  mov rax, file_length
  mov [arg1_rdi + task.arg2], rax
  mov [arg1_rdi + task.rcvr], r12
  ; mov qword [arg1_rdi + task.ridx], 1
  mov cet_r14, arg1_rdi
  jmp quicksort

.error:
  mov edx, errmsg_size
  mov esi, errmsg
  mov edi, 2  ; stderr
  mov eax, 1  ; write syscall number
  syscall
  mov edi, 7
  mov eax, 231  ; exit_group syscall number
  syscall




proc done:  ; Exit program.
  stat call print_stats
  mov edi, 0
  mov eax, 231  ; exit_group syscall number
  syscall




proc quicksort:

  %define v rax
  %define s r12
  %define e r13
  %define l rbx
  %define r rdx
  %define p rcx
  %define x rdi
  %define y rsi

  mov v, [array_ptr]
  mov l, [cet_r14 + task.arg1]
  mov s, l
  mov r, [cet_r14 + task.arg2]
  mov e, r
  mov p, [v + l]

.left:
  cmp l, r
  jnb .done
  mov x, [v + l + 8]
  cmp x, p
  jnb .right
  mov [v + l], x
  add l, 8
  jmp .left

.right:
  sub r, 8
  cmp l, r
  jnb .done
  mov y, [v + r]
  cmp y, p
  jnb .right
  mov [v + l], y
  mov [v + r], x
  add l, 8
  jmp .left

.done:
  mov [v + l], p

  ; Reuse task struc for tail-call.
  mov qword [cet_r14 + task.exec], join
  mov dword [cet_r14 + task.need], 0

  xor edi, edi
  mov rax, l
  sub rax, s
  cmp rax, 2 * 8
  jb .maybe_right

  add dword [cet_r14 + task.need], 1  ; PROBLEM
  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], quicksort
  mov [arg1_rdi + task.arg1], s
  mov [arg1_rdi + task.arg2], l
  mov [arg1_rdi + task.rcvr], cet_r14
  ; mov qword [arg1_rdi + task.ridx], 1

.maybe_right:
  add l, 8
  mov rax, e
  sub rax, l
  cmp rax, 2 * 8
  jb .no_right

  test arg1_rdi, arg1_rdi
  jz .yes_right  ; No left.
  jmp_ret sched_task  ; arg1_rdi set to left.

  ; PROBLEM: First task might finish before cet_r14's task.need is incremented
  ; below.  If it does finish before, it'll think the receiver got its final
  ; value, but that's a mistake.

.yes_right:
  add dword [cet_r14 + task.need], 1  ; PROBLEM
  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], quicksort
  mov [arg1_rdi + task.arg1], l
  mov [arg1_rdi + task.arg2], e
  mov [arg1_rdi + task.rcvr], cet_r14
  ; mov qword [arg1_rdi + task.ridx], 2
  mov cet_r14, arg1_rdi
  jmp quicksort

.no_right:
  test arg1_rdi, arg1_rdi
  jz join  ; No left either.
  mov cet_r14, arg1_rdi  ; Execute left directly.
  jmp quicksort




proc join:
  ; jmp_ret_to supply_retval, free_pet__exec_avail
  jmp_ret notify_receiver
  jmp_ret_to free_pet, exec_avail
