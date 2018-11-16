#!/bin/bash

# Easy2cmor tool
# by Paolo Davini (Oct 2018)

# script to correct wrong metadata
# renames the file, correct eventual metadata and replace if the number of files
# obtained is equal to the number of files initially found
# uses a series of user function to perform the required operation

for year in $(seq 2041 2049) ; do

# important for the file structure
expname=${expname:-qctr}
year=${year:-1950}
replace=true #set to false for testing, avoid replacement of old files

# important for the data selection in the folder: allow for a reduction of the data to be modified
#delimeter="*.nc" 	#all the files
delimeter="tos*gr*.nc"  # tos gr files
#delimeter="*SI*.nc"	#for the fix_areacello, only sea ice block 

echo "---- Correcting and renaming year $year ----"

#--------config file-----
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# since every renaming/metadata correction is specific 
# ad hoc function should be written and added when needed

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
rm -rf $TMPDIR/$delimeter

# input files to be linked
nfilein=$(ls $CMORDIR/$delimeter | wc -l)
echo "Analyzing $nfilein files..." 
ln -s $CMORDIR/$delimeter $TMPDIR/

# filelist and loop on file, calling the renamer (it can be parallelized!)
filelist=$(ls $delimeter)
for file in $filelist ; do
	fix_tos $file
	#change_email $file
	#rename_ripf $file
	#fix_areacello $file
done

# check output files
nfileout=$(ls $TMPDIR/$delimeter | wc -l)
echo "Obtained $nfileout files..." 

# if everything is fine, remove original file and replace with the new ones
if [[ $nfilein -eq $nfileout ]] ; then
	echo "Everything seems fine... Replacing directories"
	if [[ $replace == true ]] ; then
		rm $CMORDIR/$delimeter
		mv $TMPDIR/$delimeter $CMORDIR
		rmdir $TMPDIR
	fi 
fi

	
done
