#!/bin/bash

##########################
#----user defined var----#
##########################
if [ $# -lt 3 ]
then
  echo "Usage:   ./nemo_rebuilder.sh EXP YEAR1 YEAR2 [userexp]"
  echo "Example: ./nemo_rebuilder.sh io01 1990 1991"
  exit 1
fi

expname=$1
EXPID=$1
year1=$2
year2=$3

if [ $# -ge 4 ]; then
   USERexp=$4
fi
#echo "$EXPID"
#echo "$expname"

# for permissions on $SCRATCH for now USERexp and USERme are forcily the same

for year in $(seq $year1 $year2) ; do

echo "Rebuilding year ${year} ..."

# load user and machine specifics
. $ECE3_POSTPROC_TOPDIR/conf/$ECE3_POSTPROC_MACHINE/conf_nemorbld_$ECE3_POSTPROC_MACHINE.sh
# check environment
export NEMORESULTS=$(eval echo $NEMORESULTS)
export NEMORESULTS_ORG=$(eval echo ${NEMORESULTS})/org
mkdir -p $NEMORESULTS_ORG

#various details
export TMPDIR=$(eval echo $TMPDIR)
mkdir -p $TMPDIR || exit -1; cd $TMPDIR

echo "results are in $NEMORESULTS"
echo "results are in $NEMORESULTS_ORG"
echo "temp dir is $TMPDIR"

#loop on different time frequencies
for freq in $freqs ; do

   # Nemo output filenames start with...
   froot=$1_${freq}_${year}0101_${year}????
   frootmask=$1_${freq}_${year}????_${year}????
   frootyear=$1_${freq}_${year}0101_${year}1231

   # rebuild if necessary (updated by P. Davini - 2 be double-checked!)
   # 4+1 cases according to single-multi chunks and to single-multi processors
   for t in $grids ; do
       if [ -f $NEMORESULTS/${frootyear}_${t}.nc ] #a unique file exists?
       then
          echo "$t $freq single proc & single chunk already there, nothing to be done!"
          continue #yes, nothing to be done!
       else
           if [ ! -f $NEMORESULTS/${froot}_${t}_0000.nc ] #do you have many processors? 
           then
	       if [ -f $NEMORESULTS/${froot}_${t}.nc ] #NO: does it exists at least the first chunk?
               then 
		   echo "$t $freq single proc & multi chunk, concatenation..." 
               	   $ncrcat -h $NEMORESULTS/${frootmask}_${t}.nc ${frootyear}_${t}.nc #concatenate all the chunks (multi chunks - single proc)
	       else 
		   echo "$freq $t file does not exists... don't panic, just skipping it!!!!"  #noway, then quit!
		   continue
               fi
           else
	       echo "$t $freq multi proc, launching nemo_rebuild..."
               ln -s $NEMORESULTS/${frootmask}_${t}_????.nc .  #yes, so link all the file and do nemo_rebuild on each chunk 
               filelist=$(ls ${frootmask}_${t}_0000.nc)       #evalute how many chunks you have: a single chunk will be ok!
               for file in $filelist ; do                    #loop on the chunks
                    echo ${file%????????}
                    $rbld -t ${NEMO_NPROCS} ${file%????????} $(ls ${froot}_${t}_????.nc | wc -w) #rebuild (removing last characters to ignore nprocs, file count comes from froot)
               done
               if [ ! -f ${frootyear}_${t}.nc ] #check if your file file is already there (single chunk - multiple procs case)
               then
		   echo "$t $freq is also multi chunk, concatenate..."
                   $ncrcat -h ${frootmask}_${t}.nc ${frootyear}_${t}.nc #cat all the chunks for multiple starting dates (multi chunks - multi procs case)
               fi
            fi
        fi

	# Move new files
	mv ${frootyear}_${t}.nc $NEMORESULTS
    done

    #create old directory for multiproc files
    
    for t in $grids ; do
	
	# Final move multiprocs files: check again that complete file exists
	if [ -f $NEMORESULTS/${frootyear}_${t}.nc ] 
	then
            echo $t $freq exists!
	    #echo "find $NEMORESULTS -maxdepth 1 -type f -name "${frootmask}_${t}*nc" -exec find {} -not -name "${frootyear}_${t}*nc"  \;"
	    mvfiles=$(find $NEMORESULTS -maxdepth 1 -type f -name "${frootmask}_${t}*nc" -exec find {} -not -name "${frootyear}_${t}*nc"  \;  )
	    if [ ! -z $mvfiles ] 
	    then 
	    #echo $mvfiles
	    	mv $mvfiles $NEMORESULTS_ORG 
	    fi

	    # old move, deprecated
	    #echo $t $freq exists!
	    #do we have multi proc files?
	    #if [ -f $NEMORESULTS/${froot}_${t}_0000.nc ] 
	    #then
		#echo "Move multi proc files!" 
		#mv $NEMORESULTS/${frootmask}_${t}_????.nc $NEMORESULTS_ORG
	    #else
		
	    #fi
	fi
    done
done

#clean!
rm -f $TMPDIR/*.nc 
rmdir $TMPDIR

echo "Year $year completed!!"

done

echo "ECHO EVERYTHING IS DONE, HAVE A NICE DAY!!!"

