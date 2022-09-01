#! usr/bin/bash

cd Code/

perl questionMaker.pl

for d in ./Questions/*/ ; do (cd "$d" && for d in ./*/ ; do (cd "$d" && rm oldOrig && cd content && rm oldOrig && cd ..); done); done

rm -r QPhase{1,2}


