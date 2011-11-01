; TODO: The interface must be the same across the other implementations of
;       mutex-inline (futex-bivar, futex-tristate).  What about the registers
;       the syscalls don't preserve?


Instead of a futex variable having three states (unlocked, locked w/o waiters,
locked w/ waiters), have two variables: a futex, and an indication of waiters.
If the below isn't good, investigate using a 64-bit field where the low 32 bits
are the futex and the high indicate if there's waiters - this allows atomic
64-bit reads/writes of the field - does this support an implementation that is
good?

(Remember to use faster private-flaged futex syscall operations.)

; TODO: What about the registers destroyed for the syscalls?  Should the
; abstract mutex-inline interface be that all the registers used by the most
; register-using implementation are destroyed?



; Should be aligned to cache_line_size
struc mutex
  .futex:    dd 1  ; 1 = unlocked, 0 = locked
  alignb cache_line_size  ; Avoid false sharing.  TODO: Worth it?
  .waiters:  dd 0  ; Amount of waiting threads, limited to u32_max.
endstruc


macro lock_mutex 2
  ; ; Test if it's already locked, before doing expensive atomic xchg operation.
  ; TODO: Is test-only first good?  It's not a spin-loop, so I'm thinking this
  ;       isn't needed.
  ; mov %2, [%1]
  ; test %2, %2
  ; jz %%wait1
  ; It was unlocked, so try to lock it.
  xor %2, %2
  xchg [%1], %2  ; Locking automatically done for xchg.
  test %2, %2
  jz %%wait1
  ; Acquired the lock.
  jmp %%done
%%wait1:
  ; Note: wait2 loop is so that atomic inc/dec is not repeated if will just go
  ;       back to sleep.
  lock add dword [%1 + mutex.waiters], 1
%%wait2:
  futex_wait %1, 0
  ; TODO: Check syscall error status.
  ; TODO: Is %1 preserved after syscall?  If not, need to restore before continuing.
  ; It was just unlocked, so try to lock it.
  xor %2, %2
  xchg [%1], %2  ; Locking automatically done for xchg.
  test %2, %2
  jz %%wait2
  ; Acquired the lock.
  lock sub dword [%1 + mutex.waiters], 1
%%done:




macro unlock_mutex 1
  mov dword [%1], 1  ; Unlock its mutex.futex.
  test dword [%1 + mutex.waiters], -1
  jnz %%wake
  jmp %%done
%%wake:
  futex_wake %1, 1
  ; TODO: Check syscall error status.
%%done:
