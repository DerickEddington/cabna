/* This file exists so that the C Library can be initialized, for when it is
   used by a Cabna application.  It is initialized before main is called. */

extern void start_threads();

int main (int argc, char** argv) {
  start_threads();
  return 0;
}
