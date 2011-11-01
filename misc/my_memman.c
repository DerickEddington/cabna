#include <stdlib.h>
#include <stdio.h>

extern void lock (unsigned long *);
extern void unlock (unsigned long *);

#define true   1
#define false  0


#ifdef ACCOUNTING
typedef struct node {
  void* ptr;
  unsigned long a;  /* Allocation count. */
  unsigned long f;  /* Free count. */
  unsigned long c;  /* Currently allocated? */
  struct node* next;
} node;

node* allocated = NULL;
#endif

unsigned long mutex = false;


void* my_malloc (size_t size) {
  void* ptr;
#ifdef ACCOUNTING
  node* a;
  node* n;
#endif
  lock(&mutex);
  ptr = malloc(size);
#ifdef ACCOUNTING
  if (ptr != NULL) {
    a = allocated;
    while (a != NULL) {
      if (a->ptr == ptr) {
        a->a += 1;
        a->c = true;
        unlock(&mutex);
        return ptr;
      }
      a = a->next;
    }
    n = malloc(sizeof(node));
    n->ptr = ptr;
    n->a = 1;
    n->f = 0;
    n->c = true;
    n->next = allocated;
    allocated = n;
  }
#endif
  unlock(&mutex);
  return ptr;
}


void my_free (void* ptr) {
#ifdef ACCOUNTING
  node* a;
#endif
  lock(&mutex);
#ifdef ACCOUNTING
  a = allocated;
  while (a != NULL) {
    if (a->ptr == ptr) {
      if (a->c == true) {
        a->f += 1;
        a->c = false;
        free(ptr);
        unlock(&mutex);
        return;
      }
      else {
        fprintf(stderr, "Attempted to free already-free: %p\n", ptr);
        fprintf(stderr, "  a=%lu  f=%lu\n", a->a, a->f);
        unlock(&mutex);
        exit(EXIT_FAILURE);
      }
    }
    a = a->next;
  }
  a = allocated;
  while (a != NULL) {
    fprintf(stderr, "Allocated: %p\n", a->ptr);
    a = a->next;
  }
  fprintf(stderr, "Attempted to free never-allocated: %p\n", ptr);
  unlock(&mutex);
  exit(EXIT_FAILURE);
#else
  free(ptr);
  unlock(&mutex);
  return;
#endif
}
