bits 64
default rel


%include "cabna/sys/conv.nasm"


global start_threads
global threads_strucs
global thread_aligned_size
global thread_main_semaphore

extern thread_main
extern bug

; Note: There are more global and extern clauses below in the .data section.


; It is assumed that all Cabna code and data is located in 32-bit address space,
; which allows assuming Cabna addresses fit in 32 bits.  This is taken advantage
; of to use 32-bit operations instead of 64-bit, as the processor manufacturers
; recommend, when possible, for optimization, and also to fit two values in r15.
; Cabna is still a 64-bit system intended for 64-bit use, and 64-bit addresses
; and operations are used for users' stuff and strucs that might be allocated in
; 64-bit space.


; Users' responsibilities:
;  1) Task strucs must not be in more than one stack at a time.
;  2) Task strucs must not be in the same stack more than once.
;  3) The memory allocated by the OS for task strucs must never be returned to
;     the OS.
; It is assumed that users obey these responsibilities.




section .text


proc start_threads:
  ; Initialize and start the threads.  This procedure is usually called by
  ; either _start or main, but can be called whenever it is desired to start
  ; Cabna.
  mov ebx, amount_threads
.loop:
  sub ebx, 1
  jz .done

  ; Get space for the threads' stacks, via mmap.
  xor r9d, r9d              ; pgoffset
  mov r8, dword -1          ; fd
  mov r10d, 0x20022         ; flags = MAP_PRIVATE | MAP_ANONYMOUS | MAP_STACK
  mov edx, 3                ; prot = PROT_READ | PROT_WRITE
  mov esi, call_stack_size  ; length
  xor edi, edi              ; addr = NULL
  mov eax, 9                ; mmap syscall number
  syscall
  cmp rax, -4096
  ja .mmap_failed

  ; Create the threads using clone.
  xor r8d, r8d         ; tls = NULL
  xor r10d, r10d       ; ctid = NULL
  xor edx, edx         ; ptid = NULL
  add rax, call_stack_size
  mov rsi, rax         ; child_stack = end of mmap'ed memory
  mov edi, 0x80012F00  ; flags = CLONE_FILES | CLONE_FS | CLONE_IO | CLONE_PTRACE
                       ;         | CLONE_SIGHAND | CLONE_THREAD | CLONE_VM
  mov eax, 56          ; clone syscall number
  syscall
  cmp rax, -4096
  ja .clone_failed

  test rax, rax
  jnz .loop  ; Caller of clone jumps.  New threads don't.

.done:
  ; Set the threads' data struc register.
  mov eax, thread_aligned_size
  mul ebx
  jc .too_many_threads
  add eax, threads_strucs
  jc .too_many_threads
  mov tds_r15d, eax
  ; Begin executing the user's program.
  mov edi, ebx  ; Thread ID is the argument to thread_main.
  jmp thread_main
  ; TODO?: Call thread_main and after do exit syscall?

.mmap_failed:
  ; TODO: Negated error code is in rax, print to stderr, and do something...
  jmp bug

.clone_failed:
  ; TODO: Negated error code is in rax, print to stderr, and do something...
  jmp bug

.too_many_threads:
  ; TODO: Print something to stderr...
  jmp bug




section .data  align=128

; Variables and strucs are aligned at 128-byte boundary because this improves
; cache-coherency performance by avoiding "false sharing" of cache lines, and
; because this improves the performance of processor bus locking used for atomic
; operations by avoiding locking cache lines of other variables.  It also makes
; the needed 8-byte alignment for atomic field access.


; Threads' data strucs.

threads_strucs:

%assign n 0
%rep amount_threads


global thread_%[n]
extern allocatables_%[n]_head


thread_%[n]:

istruc thread
  at thread.executables,    dq 0
  at thread.allocatables,   dq allocatables_%[n]_head
  at thread.gift,           dq 0
  at thread.orphans,        dq 0
%ifdef statistics_collection
  at thread.exec_s_max,     dq 0
  at thread.exec_s_size,    dq 0
  at thread.execute_calls,  dq 0
  at thread.executed_mine,  dq 0
  at thread.needy,          dq 0
  at thread.sched_calls,    dq 0
  at thread.sched_mine,     dq 0
  at thread.alloc_s_max,    dq amount_prealloc_tasks
  at thread.alloc_s_size,   dq amount_prealloc_tasks
  at thread.allocate_calls, dq 0
  at thread.alloc_orphans,  dq 0
  at thread.freed,          dq 0
  at thread.freed_orphans,  dq 0
  at thread.mmap,           dq 0
%endif
iend

align 128, db 0

thread_%[n]_end:  ; Used to calculate thread_aligned_size.

%assign n  n + 1
%endrep




; The byte length from a thread struc to the next.  (equ makes it an absolute
; symbol - it's not in any section.)
thread_aligned_size:  equ  thread_0_end - thread_0




; The semaphore used by the thread_main_race macro.
thread_main_semaphore: dd 1
