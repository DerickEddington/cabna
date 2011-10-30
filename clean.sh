dirs=". sys sys/sched-exec sys/task-alloc lib tests tests/tbb"
exts=".o .lf .od .exe ~"

for D in $dirs
do
  for E in $exts
  do
    rm -f $D/*$E
  done
done
