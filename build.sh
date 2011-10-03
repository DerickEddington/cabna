#! /bin/bash

rm -f {.,tests}/*.{o,lf,exe,od}

for F in impl bug tests/quicksort tests/summation tests/fibonacci tests/counter tests/counter-reuse
  do nasm -f elf64 -g -F dwarf -Ox -I ../ -l $F.lf $F
done

for T in quicksort counter counter-reuse
do
  ld -o tests/$T.exe impl.o bug.o tests/$T.o #-I /lib64/ld-linux-x86-64.so.2 -l c
done

for T in summation fibonacci
do
  ld -o tests/$T.exe -I /lib64/ld-linux-x86-64.so.2 -l c impl.o bug.o tests/$T.o
done

for T in quicksort summation fibonacci counter counter-reuse
do
  objdump -M intel-mnemonic -x -s -d tests/$T.exe >tests/$T.exe.od
done
