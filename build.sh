#! /bin/bash

tests_solo="tests/quicksort tests/counter tests/counter-reuse"
tests_libc="tests/summation tests/fibonacci tests/fibonacci-limited tests/tbb/sudoku"
tests_all="$tests_solo $tests_libc"

rm -f {.,tests}/*.{o,lf,exe,od}

for F in impl bug $tests_all
  do nasm -f elf64 -g -F dwarf -Ox -I ../ -l $F.lf $F
done

for T in $tests_solo
do
  ld -o $T.exe impl.o bug.o $T.o #-I /lib64/ld-linux-x86-64.so.2 -l c
done

for T in $tests_libc
do
  gcc -Wall -O1 -g -o $T.exe c-main.c impl.o bug.o $T.o
done

for T in $tests_all
do
  objdump -M intel-mnemonic -x -s -d $T.exe >$T.exe.od
done
