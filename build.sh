#! /bin/bash

# These variables can be changed, to use different implementations.
sched_exec="needy-spin"
task_alloc="orphans-incr"

sys_src="sys/threads
         sys/prealloc-tasks
         sys/receive
         sys/sched-exec/$sched_exec
         sys/task-alloc/$task_alloc
         sys/bug"

#sys_src+=" sys/stats"

sys_obj=$(for F in $sys_src ; do echo $F.o ; done)


lib_src=""


tests_solo="tests/quicksort
            tests/counter
            tests/counter-reuse"

tests_libc="tests/summation
            tests/summation-limited
            tests/fibonacci
            tests/fibonacci-limited
            tests/shootout/threadring
            tests/tbb/sudoku"

tests_all="$tests_solo $tests_libc"


for F in  $sys_src  $lib_src  $tests_all
do
  nasm_opts="-Ox  -g -F dwarf  -l $F.lf"
  nasm  -f elf64  $nasm_opts  -I ../  -o $F.o  $F.nasm
done

for T in $tests_solo
do
  ld  -o $T.exe  $sys_obj  $T.o  #-I /lib64/ld-linux-x86-64.so.2  -l c
done

for T in $tests_libc
do
  gcc_opts="-Wall -no-pie -O1 -g"
  gcc  $gcc_opts  -o $T.exe  sys/c-main.c  $sys_obj  $T.o
done

for T in $tests_all
do
  objdump  -M intel-mnemonic  -x  -d  $T.exe  >$T.exe.od
done
