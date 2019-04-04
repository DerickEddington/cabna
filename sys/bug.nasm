global bug


section .data
message: db `Cabna bug!\n`,0
message_size  equ  $ - message


section .text

bug:
  mov edx, message_size
  mov esi, message
  mov edi, 1  ; stdout
  mov eax, 1  ; write syscall number
  syscall

  mov edi, 7    ; exit code
  mov eax, 231  ; exit_group syscall number
  syscall
