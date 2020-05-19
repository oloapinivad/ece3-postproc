#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)

# script to correct wrong metadata
# renames the file, correct eventual metadata and replace if the number of files
# obtained is equal to the number of files initially found
# uses a series of user function to perform the required operation

#for year in $(seq 1850 1859) ; do

# important for the file structure
expname=${expname:-v126}
year=${year:-2015}
replace=true #set to false for testing, avoid replacement of old files

# important for the data selection in the folder: allow for a reduction of the data to be modified
delimeter="*.nc" 	#all the files
#delimeter="tos*gr*.nc"  # tos gr files
#delimeter="*SI*.nc"	#for the fix_areacello, only sea ice block 

echo "---- Correcting and renaming year $year ----"

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# since every renaming/metadata correction is specific 
# ad hoc function should be written and added when needed

# fix reference time for LPJG runs
function fix_ref_time {
	file=$1
	check1=$( ncdump -h $file | fgrep -e time:units | grep "00:00:00" ) 
	check2=$( ncdump -h $file | fgrep -e time:units ) 
	if [[ -z $check1 ]] && [[ ! -z $check2 ]]  ; then  
		echo "Fixing file... $file"
		$ncatted -a units,time,m,c,"days since 1970-01-01 00:00:00" $file
	else 
		echo "No need for this!"
	fi
}

# fix wrong branch time for scenarios
function fix_branch_time_ssp {
	file=$1
	$ncatted -a branch_time_in_child,global,m,c,60265. $file
	$ncatted -a branch_time_in_parent,global,m,c,60265. $file
	$ncatted -a branch_time,global,d,c, $file
}

# fix wrong branch time for scenarios
function fix_branch_time_amip {
        file=$1
        $ncatted -a branch_time_in_child,global,d,c, $file
        $ncatted -a branch_time_in_parent,global,d,c, $file
        $ncatted -a branch_time,global,d,c, $file
}
	

# first example: rename the phisical index changing the block of the ripf identifier
function rename_ripf { 

	# it works only for change in the physics index, can be generalized
	ph_idx=2
	oldripf=r1i1p1f1
        newripf=r1i1p${ph_idx}f1

	file=$1
	#echo "Old file name... $file"
        echo "New file name... ${file/$oldripf/$newripf}"
        newfile=${file/$oldripf/$newripf}
        if [ ! -f $newfile ]  ; then
                cp $file ${newfile}
        fi

        #operation to be performed
        echo "Correcting attributes..."
        $ncatted -a variant_label,global,m,c,$newripf $newfile
        $ncatted -a parent_variant_label,global,m,c,$newripf $newfile
        $ncatted -a physics_index,global,m,i,$ph_idx $newfile
	
	# check this line, it changes for every experiment!!
        $ncatted -a further_info_url,global,m,c,https://furtherinfo.es-doc.org/CMIP6.EC-Earth-Consortium.EC-Earth3P-HR.control-1950.none.$newripf $newfile
        echo "Done!"
        rm $file
}

function fix_areacello { 
	file=$1
	cp --remove-destination "$(readlink $file)" $file
	header=$(echo $file | cut -f1,2  -d"_")
	var=$(echo $file | cut -f1  -d"_")
	tocorrect="siage_SImon sicompstren_SImon siflswdtop_SImon sisali_SImon sispeed_SImon sitemptop_SImon sithick_SImon sithick_SIday"
	for corr in $tocorrect ; do 
		#operation to be performed
		if [[ $header == $corr ]] ; then
        		echo "Correcting attributes for $header ..."
			$ncatted -a cell_measures,$var,m,c,"area: areacello" $file
			echo "Done!"
		fi
	done
}

function change_email {
        file=$1
        cp --remove-destination "$(readlink $file)" $file
        echo "Correcting mail for $file ..."
        $ncatted -a contact,global,m,c,"cmip6-data@ec-earth.org" $file
}



function fix_tos {
        file=$1
        cp --remove-destination "$(readlink $file)" $file
        echo "Correcting tos for $file ..."
        $ncap2 -s "tos=tos-273.15;" $file tmp.nc
	mv tmp.nc $file
}


	
# find directory (should be integrated in easy2cmor3)	
CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
TMPDIR=$BASETMPDIR/rename_${year}
mkdir -p $TMPDIR; cd $TMPDIR

# clean possible mistakes 
rm -rf $TMPDIR

# input files to be linked
echo "Browsing $CMORDIR"
filelist=$(cd $CMORDIR && find . -type f -name $delimeter -printf '%P\n')
nfilein=$(cd $CMORDIR && find . -type f -name $delimeter | wc -l )
echo "Analyzing $nfilein files..." 

# filelist and loop on file, calling the renamer (it can be parallelized!)
#filelist=$(ls $delimeter)
for file in $filelist ; do
	basefile=$(basename $file)
	basedir=$(dirname $file)
	mkdir -p $TMPDIR/$basedir
	cp -r $CMORDIR/$file $TMPDIR/$basedir
	#fix_tos $file
	#change_email $file
	#rename_ripf $file
	#fix_areacello $file
	echo $file
	fix_ref_time $TMPDIR/$basedir/$basefile
	#fix_branch_time_ssp $TMPDIR/$basedir/$basefile
done

# check output files
nfileout=$(cd $TMPDIR && find . -type f -name $delimeter | wc -l )
echo "Obtained $nfileout files..." 

# if everything is fine, remove original file and replace with the new ones
if [[ $nfilein -eq $nfileout ]] ; then
	echo "Everything seems fine... Replacing directories"
	if [[ $replace == true ]] ; then
		rm -rf $CMORDIR
		mv $TMPDIR $CMORDIR
		rmdir $TMPDIR
	fi 
fi

	
