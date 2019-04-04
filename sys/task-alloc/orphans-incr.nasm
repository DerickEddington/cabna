bits 64
default rel


%include "cabna/sys/conv.nasm"


global alloc_task
global free_pet

extern bug

%ifdef statistics_collection
extern used_max
extern in_use
%endif




section .text


proc alloc_task:
  ; Pop a free task struc from the thread's private allocatable-tasks stack, or
  ; see if other threads have freed any of the thread's strucs, or allocate more
  ; memory from the OS, and return to ret_rsi with task pointer in arg1_rdi.
  ; Used registers: rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11.

%ifdef statistics_collection
  add qword [tds_r15d + thread.allocate_calls], 1
  mov ecx, 1
  lock xadd [in_use], rcx
  add rcx, 1
  mov rax, [used_max]
.retry_max:
  cmp rcx, rax
  jbe .not_used_max
  lock cmpxchg [used_max], rcx
  jne .retry_max
.not_used_max:
%endif

  mov arg1_rdi, [tds_r15d + thread.allocatables]
  test arg1_rdi, arg1_rdi
  jz .orphans

.done:
  ; The next, which might be null, becomes the head.
  mov rax, [arg1_rdi + task.next]
  mov [tds_r15d + thread.allocatables], rax
  mov qword [arg1_rdi + task.next], 0
  stat sub qword [tds_r15d + thread.alloc_s_size], 1
  jmp_ind ret_rsi

.orphans:
  mov rax, [tds_r15d + thread.orphans]
  test rax, rax
  jz .get_new_space
  ; The field will still be non-null if another thread changes it.
  ; arg1_rdi already null.
  xchg [tds_r15d + thread.orphans], arg1_rdi  ; Locking automatically done for xchg.
%ifdef statistics_collection
  mov rax, arg1_rdi
  xor ecx, ecx
.orphans_size:
  add rcx, 1
  mov rax, [rax + task.next]
  test rax, rax
  jnz .orphans_size
  mov [tds_r15d + thread.alloc_s_size], rcx
  cmp rcx, [tds_r15d + thread.alloc_s_max]
  jbe .not_alloc_s_max
  mov [tds_r15d + thread.alloc_s_max], rcx
.not_alloc_s_max:
  add qword [tds_r15d + thread.alloc_orphans], 1
%endif
  jmp .done

.get_new_space:
  ; Get some more space from the OS, divide into blocks of task strucs, link
  ; together, push-at-once, and return a struc.  The unset fields of the new
  ; strucs are null because mmap zeros, as needed for future operations.

  ; Save registers.
  ;mov ?, r9
  ;mov ?, r8
  ;mov ?, r10
  ;mov ?, rdx
  mov [tds_r15d + thread.allocatables], ret_rsi  ; Just a temporary location.
  ;mov ?, rdi
  ;mov ?, rax  ; syscall destroys
  ;mov ?, rcx  ; syscall destroys
  ;mov ?, r11  ; syscall destroys

  ; mmap a space.
  xor r9d, r9d                     ; pgoffset
  mov r8, dword -1                 ; fd
  mov r10d, 0x22                   ; flags = MAP_PRIVATE | MAP_ANONYMOUS
  mov edx, 3                       ; prot = PROT_READ | PROT_WRITE
  mov esi, mmap_tasks * task_size  ; length
  xor edi, edi                     ; addr = NULL
  mov eax, 9                       ; mmap syscall number
  syscall
  cmp rax, -4096
  ja .mmap_failed

  ; Reserve first struc for return value.
  mov arg1_rdi, rax
  mov [rax + task.owner], tds_r15d
  ; Divide remaining space into task strucs, and link together.
  add rax, rsi  ; End of the space.
  sub rax, task_size  ; Tail struc is the last block.
  xor edx, edx
.divide_and_link:
  mov [rax + task.owner], tds_r15d
  mov [rax + task.next], rdx
  mov rdx, rax
  sub rax, task_size
  cmp rax, arg1_rdi
  ja .divide_and_link
  mov ret_rsi, [tds_r15d + thread.allocatables]  ; Restore saved.
  mov [tds_r15d + thread.allocatables], rdx
%ifdef statistics_collection
  mov eax, mmap_tasks - 1
  mov [tds_r15d + thread.alloc_s_size], rax
  cmp rax, [tds_r15d + thread.alloc_s_max]
  jbe .not_alloc_s_max_2
  mov [tds_r15d + thread.alloc_s_max], rax
.not_alloc_s_max_2:
  add qword [tds_r15d + thread.mmap], 1
%endif
  jmp_ind ret_rsi

.mmap_failed:
  ; TODO: Negated error code is in rax, print to stderr, and do something...
  jmp bug




proc free_pet:
  ; Free the previously executing task by pushing it in the thread's private
  ; allocatable-tasks stack; or if the struc belongs to another thread, give it
  ; to the owner; and return to ret_rsi.
  ; Used registers: rax, rdx, rsi.

  stat lock sub qword [in_use], 1
  stat add qword [tds_r15d + thread.freed], 1

  mov edx, [cet_r14 + task.owner]
  cmp edx, tds_r15d
  jne .orphan

  mov rax, [tds_r15d + thread.allocatables]
  mov [cet_r14 + task.next], rax
  mov [tds_r15d + thread.allocatables], cet_r14

%ifdef statistics_collection
  mov rax, [tds_r15d + thread.alloc_s_size]
  add rax, 1
  mov [tds_r15d + thread.alloc_s_size], rax
  cmp rax, [tds_r15d + thread.alloc_s_max]
  jbe .not_max
  mov [tds_r15d + thread.alloc_s_max], rax
.not_max:
%endif

  jmp_ind ret_rsi

.orphan:
  mov rax, [edx + thread.orphans]
.retry:
  ; pause  ; Not needed, I think, because the lock cmpxchg is always done.
  mov [cet_r14 + task.next], rax
  lock cmpxchg [edx + thread.orphans], cet_r14
  jne .retry
  stat add qword [tds_r15d + thread.freed_orphans], 1
  jmp_ind ret_rsi
