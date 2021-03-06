global thread_main
extern malloc
extern free
extern fopen
extern fclose
extern fscanf
extern printf
extern perror

default rel

%include "cabna/sys/iface.nasm"

%assign board_dim   9
%assign board_size  board_dim * board_dim

struc element
  .value:       resd 1
  .potentials:  resd 1
endstruc




section .data
amount_solutions: dd 0
file_name:  db `tests/tbb/input3`,0
file_mode:  db `r`,0
scanf_str:  db `%d`,0
fmtstr1:    db `Found first solution.\n`,0
fmtstr2:    db `Found all %d solutions.\n`,0




section .text

proc thread_main:
  thread_main_race

  mov edi, board_size * element_size
  call malloc
  test rax, rax
  jz .error
  mov rbp, rax

  ; Read and initialize board.
  mov esi, file_mode
  mov edi, file_name
  call fopen
  test rax, rax
  jz .error
  mov r12, rax

  sub rsp, 8
  xor ebx, ebx
.loop:
  mov rdx, rsp
  mov esi, scanf_str
  mov rdi, r12
  xor eax, eax
  call fscanf
  test rax, rax
  jz .error
  mov eax, [rsp]
  mov [rbp + element_size * rbx + element.value], eax
  mov dword [rbp + element_size * rbx + element.potentials], 0
  add ebx, 1
  cmp ebx, board_size
  jb .loop
  add rsp, 8
  mov rdi, r12
  call fclose
  test rax, rax
  jnz .error

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], done
  mov qword [arg1_rdi + task.need], 1
  mov rbx, arg1_rdi

  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], solve
  mov [arg1_rdi + task.arg1], rbp
  mov qword [arg1_rdi + task.arg2], 0
  mov [arg1_rdi + task.rcvr], rbx
  mov cet_r14, arg1_rdi
  jmp solve

.error:
  xor edi, edi
  call perror
  mov edi, 1
  mov eax, 231  ; exit_group syscall number
  syscall




proc done:
  mov esi, [amount_solutions]
  mov edi, fmtstr2
  xor eax, eax
  call printf
  stat call print_stats
  mov edi, 0
  mov eax, 231  ; exit_group syscall number
  syscall




proc solve:

%define b rbp

  mov b, [cet_r14 + task.arg1]
.recur:
  ; Is board solved?
  mov ecx, board_size - 1
.check_solved:
  mov eax, [b + element_size * rcx + element.value]
  test eax, eax
  jz .not_solved
  sub ecx, 1
  jnc .check_solved
  ; It is solved.
  lock add dword [amount_solutions], 1
  jmp branch_done

.not_solved:

%define row      r10d
%define col      r11d

%define valid    r12d
%define progress r13d

%define rv  edi
%define ei  ecx
%define eiq rcx
%define ri  edx
%define ci  eax
%define blr r8d
%define blc r9d

; Registers that can't be mutated:
;   rbx - Index of outermost loop's current board element.
;   rsi - Argument to in_* macros.
;   rbp - Points to the board.
;   rsp - Stack pointer.
;   r14 - Pointer to currently executing task.
;   r15 - Pointer to thread data struc.

%macro in_row 1
  lea ri, [8 * row + row]  ; Multiply by 9 (board_dim).
  xor rv, rv   ; Return value defaults to false.
  xor ci, ci   ; Column index.
%%loop:
  cmp ci, col
  je %%loop_end
  mov ei, ri
  add ei, ci
  cmp %1, [b + element_size * eiq + element.value]
  jne %%loop_end
  not rv  ; Set to true.
  jmp %%done
%%loop_end:
  add ci, 1
  cmp ci, board_dim
  jb %%loop
%%done:
%endmacro

%macro in_col 1
  xor rv, rv  ; Return value defaults to false.
  xor ri, ri  ; Row index.
%%loop:
  cmp ri, row
  je %%loop_end
  lea ei, [8 * ri + ri]  ; Multiply by 9 (board_dim).
  add ei, col
  cmp %1, [b + element_size * eiq + element.value]
  jne %%loop_end
  not rv  ; Set to true.
  jmp %%done
%%loop_end:
  add ri, 1
  cmp ri, board_dim
  jb %%loop
%%done:
%endmacro

%macro in_block 1
  ; Block's first row index.
  xor edx, edx
  mov eax, row
  mov edi, 3
  div edi
  lea blr, [2 * eax + eax]  ; Multiply quotient by 3;
  ; Block's first column index.
  xor edx, edx
  mov eax, col
  ; mov edi, 3
  div edi
  lea blc, [2 * eax + eax]  ; Multiply quotient by 3;
  xor rv, rv  ; Return value defaults to false.
  mov ri, blr
  ; The end bounds of the block.
  add blr, 3
  add blc, 3
%%rloop:
  mov ci, blc
  sub ci, 3
%%cloop:
  cmp ri, row
  jne %%test
  cmp ci, col
  je %%cloop_end
%%test:
  lea ei, [8 * ri + ri]  ; Multiply by 9 (board_dim).
  add ei, ci
  cmp %1, [b + element_size * eiq + element.value]
  jne %%cloop_end
  not rv  ; Set to true.
  jmp %%done
%%cloop_end:
  add ci, 1
  cmp ci, blc
  jb %%cloop
%%rloop_end:
  add ri, 1
  cmp ri, blr
  jb %%rloop
%%done:
%endmacro

  ; Calculate potentials.
%define p esi
  xor ebx, ebx
.calc:
  mov dword [b + element_size * rbx + element.potentials], 0
  mov eax, [b + element_size * rbx + element.value]
  test eax, eax
  jnz .calc_end
  xor edx, edx
  mov eax, ebx
  mov edi, board_dim
  div edi
  mov row, eax
  mov col, edx
  mov p, 1
.calc_ploop:
  in_row p
  test edi, edi
  jnz .calc_ploop_end
  in_col p
  test edi, edi
  jnz .calc_ploop_end
  in_block p
  test edi, edi
  jnz .calc_ploop_end
  mov ecx, p
  sub ecx, 1
  mov eax, 1
  shl eax, cl
  or [b + element_size * rbx + element.potentials], eax
.calc_ploop_end:
  add p, 1
  cmp p, board_dim
  jbe .calc_ploop
.calc_end:
  add ebx, 1
  cmp ebx, board_size
  jb .calc

  ; Examine potentials.
  xor valid, valid
  xor progress, progress
  xor ebx, ebx
.examine:
  mov edi, [b + element_size * rbx + element.value]
  mov eax, [b + element_size * rbx + element.potentials]
  test edi, edi
  jnz .examine_more
  test eax, eax
  jz .examine_done  ; valid already false.
.examine_more:
  popcnt edi, eax  ; How many bits/potentials set?
  cmp edi, 1       ; Only one potential?
  jne .examine_end
  bsf edi, eax     ; What is the potential's value?
  add edi, 1
  mov [b + element_size * rbx + element.value], edi
  mov progress, 1  ; Set to true.
.examine_end:
  add ebx, 1
  cmp ebx, board_size
  jb .examine

  ; Is board valid now?
%define v esi
  xor ebx, ebx
.validate:
  mov v, [b + element_size * rbx + element.value]
  test v, v
  jz .validate_end
  xor edx, edx
  mov eax, ebx
  mov edi, board_dim
  div edi
  mov row, eax
  mov col, edx
  in_row v
  test edi, edi
  jnz .examine_done  ; valid already false.
  in_col v
  test edi, edi
  jnz .examine_done  ; valid already false.
  in_block v
  test edi, edi
  jnz .examine_done  ; valid already false.
.validate_end:
  add ebx, 1
  cmp ebx, board_size
  jb .validate
  mov valid, 1  ; Set to true.

.examine_done:
  test valid, valid
  jz branch_done
  test progress, progress
  jnz .recur  ; Recur with new element values.

  ; Try a further partial permutation.

; These registers, and b, are preserved across procedure calls.
%define u rbx
%define p r12d
%define s r13

  ; Find the next unset element.
  mov u, [cet_r14 + task.arg2]
.next_unset:
  mov eax, [b + element_size * u + element.value]
  test eax, eax
  jz .potentials
  add u, 1
  jmp .next_unset

.potentials:
  ; Reuse task struc for notification of child tasks completion.
  mov qword [cet_r14 + task.exec], branch_done
  popcnt eax, [b + element_size * u + element.potentials]  ; How many potentials?
  mov [cet_r14 + task.need], eax  ; Always at least 2.
  mov p, 1
.loop:
  mov ecx, p
  sub ecx, 1
  mov eax, 1
  shl eax, cl
  test eax, [b + element_size * u + element.potentials]
  jz .loop_end

  ; Copy the board, and make it a new further partial permutation.
  mov edi, board_size * element_size
  call malloc
  xor ecx, ecx
.copy:
  mov edi, [b + element_size * rcx + element.value]
  mov [rax + element_size * rcx + element.value], edi
  add ecx, 1
  cmp ecx, board_size
  jb .copy
  mov [rax + element_size * u + element.value], p

  ; Make a task to try solving this new partial permutation.
  mov s, rax
  jmp_ret alloc_task
  mov qword [arg1_rdi + task.exec], solve
  mov [arg1_rdi + task.arg1], s
  mov [arg1_rdi + task.arg2], u
  mov qword [arg1_rdi + task.rcvr], cet_r14
  jmp_ret sched_task

.loop_end:
  add p, 1
  cmp p, board_dim
  jbe .loop

  ; Have children to wait for.
  jmp exec_avail




proc branch_done:
  mov rdi, [cet_r14 + task.arg1]
  call free
  jmp_ret notify_receiver
  jmp_ret_to free_pet, exec_avail
