%include "cabna/sys/conv.nasm"


section .data  align=128

; Pre-allocated and initialized task strucs for the allocatable-tasks stacks.
; Task strucs are 128-bytes long, which preserves their 128-byte alignment when
; they are contiguously located like below.

%assign n 0
%rep amount_threads


global allocatables_%[n]_head
extern thread_%[n]


allocatables_%[n]_head:

  istruc task
    at task.next,    dq allocatables_%[n]_1
    at task.owner,   dq thread_%[n]
    at task.rcvr,    dq 0
    at task.ridx,    dq 0
    at task.need,    dq 0
    at task.exec,    dq 0
    at task.arg1,    dq 0
    at task.arg2,    dq 0
    at task.arg3,    dq 0
    at task.arg4,    dq 0
    at task.arg5,    dq 0
    at task.arg6,    dq 0
    at task.arg7,    dq 0
    at task.arg8,    dq 0
    at task.arg9,    dq 0
    at task.arg10,   dq 0
  iend


allocatables_%[n]_1:

%assign a 2
%rep amount_prealloc_tasks - 2

  istruc task
    at task.next,    dq allocatables_%[n]_%[a]
    at task.owner,   dq thread_%[n]
    at task.rcvr,    dq 0
    at task.ridx,    dq 0
    at task.need,    dq 0
    at task.exec,    dq 0
    at task.arg1,    dq 0
    at task.arg2,    dq 0
    at task.arg3,    dq 0
    at task.arg4,    dq 0
    at task.arg5,    dq 0
    at task.arg6,    dq 0
    at task.arg7,    dq 0
    at task.arg8,    dq 0
    at task.arg9,    dq 0
    at task.arg10,   dq 0
  iend

allocatables_%[n]_%[a]:

%assign a  a + 1
%endrep


  istruc task
    at task.next,    dq 0
    at task.owner,   dq thread_%[n]
    at task.rcvr,    dq 0
    at task.ridx,    dq 0
    at task.need,    dq 0
    at task.exec,    dq 0
    at task.arg1,    dq 0
    at task.arg2,    dq 0
    at task.arg3,    dq 0
    at task.arg4,    dq 0
    at task.arg5,    dq 0
    at task.arg6,    dq 0
    at task.arg7,    dq 0
    at task.arg8,    dq 0
    at task.arg9,    dq 0
    at task.arg10,   dq 0
  iend

%assign n  n + 1
%endrep
