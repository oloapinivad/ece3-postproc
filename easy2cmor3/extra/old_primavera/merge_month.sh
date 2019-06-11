#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)
# Adapted from Gijs van der Oord.
# Script to merge monthly IFS files into a single yearly file. 

set -e

expname=${expname:-det4}
year=${year:-1950}

#--------config file-----
# load user and machine specifics
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh
cd ${EASYDIR}

# setting directory
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})

#--------run the code----------

#conda activation
export PATH="$CONDADIR:$PATH"

#create merging directory
MERGEDIR=${BASETMPDIR}/merge_${year}_NCO
mkdir -p $MERGEDIR

#clean double tos (do we need it?)
#rm -rf $CMORDIR/*/*/*/*/*/*/Omon/tos/gr
#rm -rf $CMORDIR/*/*/*/*/*/*/Oday/tos/gr

source activate ece2cmor3

function gettimes {
    file=$(basename $1 ".nc")
    timint=${file##*_}
    echo $(echo "$timint" | cut -d "-" -f$2)
}

#TABS="Amon Lmon LImon Primmon Emon CFmon AERmon Omon"
#TABS="day"

export HDF5_USE_FILE_LOCKING=FALSE

for dir in `find $CMORDIR -name *.nc -print0 | xargs -0 -n 1 dirname | xargs -n 1 dirname | sort --unique`; do
    files=$(find $dir -name *.nc -printf "%f\n" | sort)
    farray=($files)
    if (( ${#farray[@]} < 2 )); then
        find $dir -name *.nc | xargs -i mv {} $MERGEDIR/
        echo "Skipping 1 or 0 files in $dir..."
        continue
    fi
    firstf=${farray[0]}
    #tab=$(echo $firstf | cut -d "_" -f2)
    #if [ "${TABS/$tab}" == "$TABS" ]; then
    #    find $dir -name *.nc | xargs -i mv {} $MERGEDIR/
    #    echo "Skipping high freq files in $dir..."
    #    continue
    #fi
    lastf=${farray[@]:(-1)}
    t1=$(gettimes $firstf 2).nc
    t2=$(gettimes $lastf 2).nc
    fname=${firstf/%$t1/$t2}
    echo "Merging files in $dir..."
    echo "Merged file name: $fname"
    orderedpaths=$(printf "%s\n" "${farray[@]}" | xargs -i find $dir -name {} -print)
    #echo $orderedpaths
    #$cdozip mergetime $orderedpaths $MERGEDIR/$fname &
    $ncrcat $orderedpaths $MERGEDIR/$fname & 
done
wait

for file in $MERGEDIR/*.nc; do
    fname=$(basename $file ".nc")
    REGEX=".*_${year}([0-9]{6})0000-${year}([0-9]{6})0000"
    if [[ $fname =~ $REGEX ]]; then
        t1=$(gettimes $file 1)
        t2=$(gettimes $file 2)
        newname=${file%_*}_${t1%00}-${t2%00}.nc
        mv $file $newname
    fi
    REGEX=".*_${year}([0-9]{4})00-${year}([0-9]{4})(18|21)"
    if [[ $fname =~ $REGEX ]]; then
        t1=$(gettimes $file 1)
        t2=$(gettimes $file 2)
        newname=${file%_*}_${t1}00-${t2}00.nc
        mv $file $newname
    fi
done

#recreate structure
#for file in $MERGEDIR/*.nc; do
	#var=$(echo $file | cut -f1 -d"_")
	#tab=$(echo $file | cut -f2 -d"_")
	#mod=$(echo $file | cut -f3 -d"_")
	#exp=$(echo $file | cut -f4 -d"_")
	#ens=$(echo $file | cut -f5 -d"_")
	#grd=$(echo $file | cut -f6 -d"_")
	#dat=v$(date '+%Y%m%d')
	#if [[ ${tab:0:4} == Prim ]] ; then
		#TGTDIR=$MERGEDIR/PRIMAVERA/PRIMAVERA/EC-Earth-Consortium/$mod/$exp/$ens/$tab/$var/$grd/$dat
	#else	
		#TGTDIR=$MERGEDIR/CMIP6/PRIMAVERA/EC-Earth-Consortium/$mod/$exp/$ens/$tab/$var/$grd/$dat
	#fi
	#mkdir -p $TGTDIR
	#mv $file $TGTDIR
#done
	

# Do this after testing...
rm -rf $CMORDIR
mv $MERGEDIR $CMORDIR

exit 0

