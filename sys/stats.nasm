bits 64
default rel


%include "cabna/sys/conv.nasm"


global print_stats
global used_max
global in_use

extern threads_strucs
extern thread_aligned_size
extern printf




section .text


proc print_stats:
  ; Print collected statistics for each thread, and print the totals of all
  ; threads.  Called directly via call not via exec_avail, so the things having
  ; statistics collected are not used to execute it.

  ; Temporary struc for the totals of all threads.
  sub rsp, thread_size
  ; [rsp + thread.exec_s_max] not totaled.
  ; [rsp + thread.exec_s_size] not totaled.
  mov qword [rsp + thread.execute_calls], 0
  mov qword [rsp + thread.executed_mine], 0
  mov qword [rsp + thread.needy], 0
  mov qword [rsp + thread.sched_calls], 0
  mov qword [rsp + thread.sched_mine], 0
  ; [rsp + thread.alloc_s_max] not totaled.
  ; [rsp + thread.alloc_s_size] not totaled.
  mov qword [rsp + thread.allocate_calls], 0
  mov qword [rsp + thread.alloc_orphans], 0
  mov qword [rsp + thread.freed], 0
  mov qword [rsp + thread.freed_orphans], 0
  mov qword [rsp + thread.mmap], 0

  mov ebx, amount_threads - 1
.loop:
  mov esi, ebx
  mov edi, stats_tid_fmtstr
  mov eax, 0
  call printf

  ; Calculate the pointer to the thread struc from the thread ID.
  mov eax, thread_aligned_size
  mul ebx
  add eax, threads_strucs
  mov ebx, eax

  mov rsi, [ebx + thread.exec_s_max]
  mov edi, stats_exec_s_max_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.exec_s_size]
  mov edi, stats_exec_s_size_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.execute_calls]
  add [rsp + thread.execute_calls], rsi
  mov edi, stats_execute_calls_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.executed_mine]
  add [rsp + thread.executed_mine], rsi
  mov edi, stats_executed_mine_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.needy]
  add [rsp + thread.needy], rsi
  mov edi, stats_needy_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.sched_calls]
  add [rsp + thread.sched_calls], rsi
  mov edi, stats_sched_calls_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.sched_mine]
  add [rsp + thread.sched_mine], rsi
  mov edi, stats_sched_mine_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.alloc_s_max]
  mov edi, stats_alloc_s_max_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.alloc_s_size]
  mov edi, stats_alloc_s_size_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.allocate_calls]
  add [rsp + thread.allocate_calls], rsi
  mov edi, stats_allocate_calls_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.alloc_orphans]
  add [rsp + thread.alloc_orphans], rsi
  mov edi, stats_alloc_orphans_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.freed]
  add [rsp + thread.freed], rsi
  mov edi, stats_freed_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.freed_orphans]
  add [rsp + thread.freed_orphans], rsi
  mov edi, stats_freed_orphans_fmtstr
  mov eax, 0
  call printf

  mov rsi, [ebx + thread.mmap]
  add [rsp + thread.mmap], rsi
  mov edi, stats_mmap_fmtstr
  mov eax, 0
  call printf

  mov eax, mmap_tasks * task_size / 1024
  mov rsi, [ebx + thread.mmap]
  mul rsi
  mov rsi, rdx
  mov rdx, rax
  mov edi, stats_mmap_kb_fmtstr
  mov eax, 0
  call printf

  ; Calculate the thread ID from the pointer to the thread struc.
  mov eax, ebx
  sub eax, threads_strucs
  xor edx, edx
  mov ebx, thread_aligned_size
  div ebx
  mov ebx, eax
  sub ebx, 1
  jnc .loop

  mov esi, amount_threads
  mov edi, stats_total_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.execute_calls]
  mov edi, stats_execute_calls_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.executed_mine]
  mov edi, stats_executed_mine_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.needy]
  mov edi, stats_needy_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.sched_calls]
  mov edi, stats_sched_calls_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.sched_mine]
  mov edi, stats_sched_mine_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.allocate_calls]
  mov edi, stats_allocate_calls_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.alloc_orphans]
  mov edi, stats_alloc_orphans_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.freed]
  mov edi, stats_freed_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.freed_orphans]
  mov edi, stats_freed_orphans_fmtstr
  mov eax, 0
  call printf

  mov rsi, [used_max]
  mov edi, stats_used_max_fmtstr
  mov eax, 0
  call printf

  mov rsi, [in_use]
  mov edi, stats_in_use_fmtstr
  mov eax, 0
  call printf

  mov rsi, [rsp + thread.mmap]
  mov edi, stats_mmap_fmtstr
  mov eax, 0
  call printf

  mov eax, mmap_tasks * task_size / 1024
  mov rsi, [rsp + thread.mmap]
  mul rsi
  mov rsi, rdx
  mov rdx, rax
  mov edi, stats_mmap_kb_fmtstr
  mov eax, 0
  call printf

  add rsp, thread_size
  ret




section .data  align=128

used_max:  dq 0
in_use:    dq 0

align 128, db 0  ; Not a serious necessity, but why not.

stats_tid_fmtstr:             db `Thread %u:\n`,0
stats_exec_s_max_fmtstr:      db `  exec_s max:    %15lu\n`,0
stats_exec_s_size_fmtstr:     db `  exec_s size:   %15lu\n`,0
stats_execute_calls_fmtstr:   db `  execute calls: %15lu\n`,0
stats_executed_mine_fmtstr:   db `  executed mine: %15lu\n`,0
stats_needy_fmtstr:           db `  needy:         %15lu\n`,0
stats_sched_calls_fmtstr:     db `  sched calls:   %15lu\n`,0
stats_sched_mine_fmtstr:      db `  sched mine:    %15lu\n`,0
stats_alloc_s_max_fmtstr:     db `  alloc_s max:   %15lu\n`,0
stats_alloc_s_size_fmtstr:    db `  alloc_s size:  %15lu\n`,0
stats_allocate_calls_fmtstr:  db `  allocate calls:%15lu\n`,0
stats_alloc_orphans_fmtstr:   db `  alloc orphans: %15lu\n`,0
stats_freed_fmtstr:           db `  freed:         %15lu\n`,0
stats_freed_orphans_fmtstr:   db `  freed orphans: %15lu\n`,0
stats_used_max_fmtstr:        db `  used max:      %15lu\n`,0
stats_in_use_fmtstr:          db `  in use:        %15lu\n`,0
stats_mmap_fmtstr:            db `  mmaps:         %15lu\n`,0
stats_mmap_kb_fmtstr:         db `  KB mmaped:     %lu,%lu\n`,0
stats_total_fmtstr:           db `Totals of %u threads:\n`,0
