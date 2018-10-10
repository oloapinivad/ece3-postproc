#!/bin/bash

# script to correct wrong metadata
# renames the file, correct eventual metadata and replace if the number of files
# obtained is equal to the number of files initially found
# P. Davini (Oct 2018)

# important for the file structure
expname=${expname:-cccc}
year=${year:-1950}

# important for the data selection in the folder
delimeter="*.nc"

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# since every renaming/metadata correction is specific 
# ad hoc function should be written and added when needed

# first example: rename the phisical index changing the block of the ripf identifier
function rename_ripf { 

	file=$1
	#echo "Old file name... $file"
        echo "New file name... ${file/r1i1p2f1/r1i1p1f1}"
        newfile=${file/r1i1p2f1/r1i1p1f1}
        if [ ! -f $newfile ]  ; then
                cp $file ${newfile}
        fi

	# 
	ph_idx=1
	
	ripf=r1i1p${ph_idx}f1

        #operation to be performed
        echo "Correcting attributes..."
        $ncatted -a variant_label,global,m,c,$ripf $newfile
        $ncatted -a parent_variant_label,global,m,c,$ripf $newfile
        $ncatted -a physics_index,global,m,i,$ph_idx $newfile
        $ncatted -a further_info_url,global,m,c,https://furtherinfo.es-doc.org/CMIP6.EC-Earth-Consortium.EC-Earth3P-HR.control-1950.none.$ripf $newfile
        echo "Done!"
        rm $file
}

function fix_areacello { 
	file=$1
	cp --remove-destination "$(readlink $file)" $file
	#operation to be performed
        echo "Correcting attributes..."
	$ncatted -a cell_measures,siage,m,c,"area: areacello" $file
	echo "Done!"
}


	
# find directory (should be integrated in easy2cmor3)	
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
TMPDIR=$BASETMPDIR/rename_${year}
mkdir -p $TMPDIR; cd $TMPDIR

# clean possible mistakes 
rm -rf $TMPDIR/$delimeter

# input files to be linked
nfilein=$(ls $CMORDIR/$delimeter | wc -l)
echo "Analyzing $nfilein files..." 
ln -s $CMORDIR/$delimeter $TMPDIR/

# filelist and loop on file, calling the renamer (it can be parallelized!)
filelist=$(ls $delimeter)
for file in $filelist ; do
	rename_ripf $file
done

# check output files
nfileout=$(ls $TMPDIR/$delimeter | wc -l)
echo "Obtained $nfileout files..." 

# if everything is fine, remove original file and replace with the new ones
if [[ $nfilein -eq $nfileout ]] ; then
	echo "Everything seems fine... Replacing directories"
	rm $CMORDIR/$delimeter
	mv $TMPDIR/$delimeter $CMORDIR
fi

rmdir $TMPDIR
	

