;--- User may modify these. ----------------------------------------------------

%assign amount_threads 4

; The size of a thread's stack, except the initial thread's.
%assign call_stack_size 4 * 4096

; The amount of pre-allocated free task strucs per thread.
%assign amount_prealloc_tasks 128  ; 16 KB

; The amount of task strucs to allocate per mmap, per thread, when more are
; needed.
%assign mmap_tasks 2048  ; 256 KB

;%define statistics_collection

;--- Internal. Do not modify. --------------------------------------------------

; These registers are reserved for the runtime system and must not be mutated by
; users.
%define tds_r15d  r15d  ; A thread's data struc (lower 32 bits).
%define cet_r14   r14   ; A thread's currently executing task.


; Procedure call arguments, including return-instruction continuation.
%define arg1_rdi  rdi
%define ret_rsi   rsi


%macro proc 1
  align 16
  %1
%endmacro


%macro jmp_ret_to 2
  mov esi, %2  ; ret_rsi. Assumes the pointer is in 32-bit space.
  jmp %1
%endmacro

%macro jmp_ret 1
  jmp_ret_to %1, %%continuation
  %%continuation:
%endmacro


; Indirect jump, more efficiently.
%macro jmp_ind 1+
  likely jmp %1  ; NOTE: Intel documents say branch-hints are only for Jcc
                 ; instructions, but the use here seems to improve speed.
  ud2  ; help branch misprediction
%endmacro


; Branch hints.
%macro likely 1+
  db 0x3E
  %1
%endmacro

%macro unlikely 1+
  db 0x2E
  %1
%endmacro


; Instances of all the below struc types must be aligned at 8-byte boundary, so
; that loads and stores of the fields are atomic.  Instances of task strucs must
; be aligned at 128-byte boundary, for processor bus locking efficiency.  Those
; pre-allocated in the .data section are properly aligned, because the section
; is specified to be aligned at 128-byte and the strucs are specified to be
; aligned at 128-byte.  Because all the strucs have qword fields, this preserves
; the correct 8-byte alignment.  Because task strucs are 128 bytes long, this
; preserves the correct 128-byte alignment when they are located contiguously.
; Task strucs dynamically allocated by mmap are properly aligned, because mmap
; allocates pages on page boundary.

; TODO?: The .need field could be the lower bits of the .next field, and the
; .ridx field could be the lower bits of the .rcvr field, because the .next and
; .rcvr fields are pointers to task strucs which are always 128-byte aligned
; which means the pointers don't need the lower 7 bits, which is enough for
; values up to 127 which is more than enough for .need and .ridx.  This would
; give 2 more argument fields, for which .need and .ridx values would range from
; 0 (.exec) to 13, which fits in 4 bits.

struc task
  .next:    resq 1
  .owner:   resq 1  ; Only low 32 bits used.
  .rcvr:    resq 1
  .ridx:    resq 1  ; Only low 32 bits used.
  .need:    resq 1  ; Updated atomically.  Only low 32 bits used.
  .exec:    resq 1
  .arg1:    resq 1
  .arg2:    resq 1
  .arg3:    resq 1
  .arg4:    resq 1
  .arg5:    resq 1
  .arg6:    resq 1
  .arg7:    resq 1
  .arg8:    resq 1
  .arg9:    resq 1
  .arg10:   resq 1
endstruc

%assign task.args task.exec

%if task_size != 128
  %error "Task size " task_size " not 128."
%endif




; Instances of thread strucs, and some of the fields, must be aligned at
; 128-byte boundary, for cache-coherency performance and for processor bus
; locking efficiency.  The .executables and .allocatables fields are private to
; a thread and not shared, so they are aligned in a cache line for both that is
; never affected by other threads.  The .gift and .orphans fields are shared and
; accessed by potentially every thread, so they are aligned in their own cache
; lines so that accessing them does not affect the cache lines of other fields
; (i.e. false sharing is avoided).  The statistics fields are private and are
; aligned so they are not in the same cache line as the orphans field.

struc thread
  .executables:    resq 1
  .allocatables:   resq 1
  alignb 128
  .gift:           resq 1
  alignb 128
  .orphans:        resq 1
%ifdef statistics_collection
  alignb 128
  .exec_s_max:     resq 1
  .exec_s_size:    resq 1
  .execute_calls:  resq 1
  .executed_mine:  resq 1
  .needy:          resq 1
  .sched_calls:    resq 1
  .sched_mine:     resq 1
  .alloc_s_max:    resq 1
  .alloc_s_size:   resq 1
  .allocate_calls: resq 1
  .alloc_orphans:  resq 1
  .freed:          resq 1
  .freed_orphans:  resq 1
  .mmap:           resq 1
%endif
endstruc




%ifdef statistics_collection

%macro stat 1+
  %1
%endmacro

%else

%macro stat 1+
%endmacro

%endif




%if amount_threads < 1
  %fatal "amount_threads, " amount_threads ", less than 1."
%endif

%if call_stack_size < 16 * 1024
  %error "call_stack_size, " call_stack_size ", less than 16 KB."
%endif

%if call_stack_size % 4096 != 0
  %warning "call_stack_size, " call_stack_size ", not a multiple of page size."
%endif

%if amount_prealloc_tasks < 2
  %fatal "amount_prealloc_tasks, " amount_prealloc_tasks ", less than 2."
%endif

%if mmap_tasks < 1
  %error "mmap_tasks, " mmap_tasks ", less than 1."
%endif

%if (mmap_tasks * task_size) % 4096 != 0
  %warning "mmap_tasks, " mmap_tasks ", size not a multiple of page size."
%endif
