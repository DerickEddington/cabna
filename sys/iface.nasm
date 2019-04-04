%include "cabna/sys/conv.nasm"

extern start_threads
extern thread_main_semaphore
extern alloc_task
extern free_pet
extern sched_task
extern exec_avail
extern notify_receiver
extern supply_retval

%ifdef statistics_collection
extern print_stats
%endif


%macro def_start 0
  proc _start:
    xor ebp, ebp  ; Unix ABI says to do this.
    jmp start_threads
%endmacro


%macro thread_main_race 1
  mov eax, [thread_main_semaphore]
  test eax, eax
  jz %1
  xor eax, eax
  xchg [thread_main_semaphore], eax  ; Locking automatically done for xchg.
  test eax, eax
  jz %1
%endmacro

%macro thread_main_race 0
  thread_main_race exec_avail
%endmacro
