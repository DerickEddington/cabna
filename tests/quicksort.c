#include <fcntl.h>
#include <sys/mman.h>
#include <stddef.h>
#include <errno.h>
#include <error.h>

typedef unsigned long  ul;
#define sz  sizeof(ul)

#define FILE_NAME    "tests/random-array-16M--C"
#define ARRAY_SIZE   (16 << 20)
#define FILE_LENGTH  (sz * ARRAY_SIZE)

static void* v;
#define VR(o)  (*((ul*)(v + (o))))


void quicksort (ul s, ul e) {
  /* Partition in-place. */
  ul l = s, r = e,
     p = VR(s),
     i, x, y;

left:
  if (l < r) {
    i = l + sz;
    x = VR(i);
    if (x < p) {
      VR(l) = x;
      l = i;
      goto left;
    }
    else goto right;
  }
  else goto done;

right:
  r -= sz;
  if (l < r) {
    y = VR(r);
    if (y < p) {
      VR(l) = y;
      VR(r) = x;
      l = i;
      goto left;
    }
    else goto right;
  }

done:
  VR(l) = p;
  if (l - s >= 2 * sz)  quicksort(s, l);
  l += sz;
  if (e - l >= 2 * sz)  quicksort(l, e);
}


int main () {
  int fd = open(FILE_NAME, O_RDWR);
  if (fd < 0)  error(1, errno, "open failed");
  v = mmap(NULL, FILE_LENGTH, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (v == MAP_FAILED)  error(1, errno, "mmap failed");
  quicksort(0, FILE_LENGTH);
  return 0;
}
