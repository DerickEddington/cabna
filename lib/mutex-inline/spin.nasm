; This is a very simple mutex implementation.  A mutex object is a 32-bit
; integer in memory (for performance it should be aligned and in its own cache
; line).  Zero means "locked" and one means "unlocked" (so that xor can be used
; to setup the "locked" value).


; TODO: The interface must be the same across the other implementations of
;       mutex-inline (futex-bivar, futex-tristate).


%macro lock_mutex 2

; %1 is the address of the mutex object, and can be any effective address.
; %2 must be a dword register.
; %1 is preserved, register %2 is not preserved.

%%retry:
  ; Test-only before writing it.
  mov %2, dword [%1]
  test %2, %2
  jz .spin
  ; It was unlocked, so try locking.
  xor %2, %2
  xchg dword [%1], %2  ; Memory-locking automatically done for xchg.
  test %2, %2
  jz .spin  ; It became locked after our first load of it.
  jmp .done
.spin:
  pause
  jmp %%retry
.done:

%endmacro




%macro unlock_mutex 1

; %1 is the address of the mutex object, and can be any effective address.

  mov dword [%1], 1

%endmacro
