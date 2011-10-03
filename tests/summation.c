#include <stdio.h>

long summation (long s, long e) {
  if (s >= e) {
    return s;
  } else if (s == (e - 1)) {
    return (s + e);
  } else {
    long x = (s + e) >> 1;
    return (summation(s, x) + summation((x + 1), e));
  }
}

int main () {
  long count = 1000000000;
  fprintf(stderr, "summation(%d, %ld) = ", 1, count);
  fprintf(stderr, "%ld\n", summation(1, count));
  return 0;
}
