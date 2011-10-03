#include <stdio.h>

unsigned long fibonacci (unsigned long n) {
  if (1 < n) {
    return fibonacci(n - 1) + fibonacci(n - 2);
  } else {
    return n;
  }
}

int main () {
  unsigned long count = 43;
  fprintf(stderr, "fibonacci(%lu) = ", count);
  fprintf(stderr, "%lu\n", fibonacci(count));
  return 0;
}
