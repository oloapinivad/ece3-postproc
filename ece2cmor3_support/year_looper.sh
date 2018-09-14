#!/bin/bash

#rough scheme for looping on years, it produces 13 jobs for each year so beware

EXP=det4
YEAR1=1961
YEAR2=1980
INDEX=1
ATM=1
OCE=0

#simple loop
for YEAR in $(seq $YEAR1 $YEAR2) ; do
	./submit_year.sh -e $EXP -y $YEAR -i 1 -a 1 -o 0
done 





