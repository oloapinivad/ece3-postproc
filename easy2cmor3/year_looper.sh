#!/bin/bash

#rough scheme for looping on years, it produces 13 jobs for each year so beware

EXP=qctr
YEAR1=1980
YEAR2=1980
ATM=0
OCE=0
MERGE=1
VALID=1
RESO=T511

#simple loop
for YEAR in $(seq $YEAR1 $YEAR2) ; do
	./submit_year.sh -e $EXP -y $YEAR -j $YEAR1 -r $RESO  \
			 -a $ATM -o $OCE -m $MERGE -v $VALID
done 





