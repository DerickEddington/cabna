(library (fibonacci)
  (export main allocs)
  (import (rnrs))
  (define (main n)
    (if (< 1 n)
      (+ (main (- n 2)) (main (- n 1)))
      n))
  (define (allocs n)
    (if (< 1 n)
      (+ 2 (allocs (- n 2)) (allocs (- n 1)))
      0)))