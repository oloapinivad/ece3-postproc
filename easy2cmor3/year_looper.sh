#!/bin/bash

#rough scheme for looping on years, it produces 13 jobs for each year so beware

EXP=cccc
YEAR1=1950
YEAR2=1950
INDEX=1
ATM=1
OCE=1
MERGE=1
VALID=1
RESO=T255

#simple loop
for YEAR in $(seq $YEAR1 $YEAR2) ; do
	./submit_year.sh -e $EXP -y $YEAR -j $YEAR1 -i $INDEX -r $RESO  \
			 -a $ATM -o $OCE -m $MERGE -v $VALID
done 





