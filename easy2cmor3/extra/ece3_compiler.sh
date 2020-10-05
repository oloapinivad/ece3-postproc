#!/bin/bash
set -e

# ece3_compiler.sh
# P. Davini (CNR)
# Jul 2019

# this is a basic script which performs the checkout, compilation and configuration
# of a required revision (from the trunk) of EC-Earth3. 
# It is meant to work on ECMWF machine but it can be adapted for further architecture.

# if you want to use eccodes, extra modification must be adopted
# https://dev.ec-earth.org/projects/ecearth3/wiki/Using_eccodes_library


#---------------------#

# this are the compiling environment needed

# ECMWF - CCA-intel - Sep 2019
module load PrgEnv-intel
module unload cray-netcdf-hdf5parallel cray-hdf5-parallel eccodes netcdf4 grib_api
#module load cray-hdf5-parallel/1.10.0.1
#module load cray-netcdf-hdf5parallel/4.4.1.1
module load cray-hdf5-parallel/1.8.14 # forcily needed by runoffmapper
module load cray-netcdf-hdf5parallel/4.3.3.1 #as above
module load grib_api/1.27.0
module load netcdf4/4.6.2

# ECMWF - CCA-intel - Jun 2019  
#module load cray-hdf5-parallel/1.8.14 # forcily needed by runoffmapper
#module load cray-netcdf-hdf5parallel/4.3.3.1 #as above
#module load eccodes/2.12.5
#module load grib_api/1.12.3 # needed by IFS
#module load netcdf4/4.6.2


# script to compile EC-Earth with a single command
do_svn=true # checkout
do_compile=true # compilation
do_runconfig=true # configuration
do_clean=false # make clean: not working

# if you want to download a specific maintenance or tag, it would be better to always download the
# corresponding revision number in order to not be confused
# Interrogation can be done with svn log https://svn.ec-earth.org/ecearth3/tags/3.3.2.1 -v --stop-on-copy

# user configuration
revision="8037" #which revision do you want?
#version=trunk
version=branches/development/2020/r7925-covid19-experiments
platform_src=ecmwf-cca-intel-mpi # src architecture
platform_run=ecmwf-cca-intel # runtime architecture
do_lpjg=false # do want lpjg?
nemo_config=ORCA1L75_LIM3 #which nemo configuration do you want?
rxxxx="covid19-r$revision"

# hard coded option
SRCDIR=$PERM/ecearth3/revisions/$rxxxx/sources
RUNDIR=$PERM/ecearth3/revisions/$rxxxx/runtime/classic
ecconfexe=$SRCDIR/util/ec-conf/ec-conf

# ad hoc function to replace the required value 3 lines after in xml
# playing with sed, adding tabulation, risky but it works
function_replacer () {
        fullstringnew="            <Value>$3</Value>"
        sed -i "/name=\"$2/{n;n;n;s#.*#${fullstringnew}#;}" $1
        echo "Replacing $2 with $3 in file $1"

}

# running the program
#------------------------------------------------#

# SVN checkout of the required revision
if [[ $do_svn == true ]] ; then
	svn checkout -r $revision  https://svn.ec-earth.org/ecearth3/$version $PERM/ecearth3/revisions/$rxxxx
fi

# go to target directory
cd $SRCDIR

# clean the code: not yet implemented
#if [[ $do_clean == true ]] ; then
	#ifs --> make clean BUILD_ARCH=ecconf 
	#xios -> --full option in compilation to fo it from scratch
	#amip-forcing & runoff-mapper -> make clean
	#oasis -> rm ecconf
	#nemo -> ./makenemo -n $config clean
#fi

# compilation
if [[ $do_compile == true ]] ; then

	# set source path within file
	cd $SRCDIR
	templatefile=$SRCDIR/platform/${platform_src}.xml
	stringmatch=ECEARTH_SRC_DIR
	stringnew=${SRCDIR}
	function_replacer $templatefile $stringmatch $stringnew

	# ecconf
	$ecconfexe -p ${platform_src} $SRCDIR/config-build.xml

	# oasis
	cd oasis3-mct/util/make_dir
	make BUILD_ARCH=ecconf -f TopMakefileOasis3
	cd $SRCDIR

	# oasis
	cd xios-2.5
	./make_xios --arch ecconf --use_oasis oasis3_mct --netcdf_lib netcdf4_par --job 8
	cd $SRCDIR

	# amip forcing
	cd amip-forcing/src
	make
	cd $SRCDIR

	# runoff mapper
	cd runoff-mapper/src
	make
	cd $SRCDIR

	# ifs
	cd ifs-36r4
	make BUILD_ARCH=ecconf -j 4 lib
	make BUILD_ARCH=ecconf master
	cd $SRCDIR

	# nemo
	cd nemo-3.6/CONFIG
	./makenemo -n $nemo_config -m ecconf -j 4
	cd $SRCDIR

	#ELPin
	cd util/ELPiN
	make
	cd $SRCDIR

	# lpjg
	if [[ $do_lpjg == true ]] ; then
		cd lpjg/build
		cmake ..
		make
	fi

fi 

if [[ $do_runconfig == true ]] ; then

	# set source path within file
	templatefile=$RUNDIR/platform/${platform_run}.xml
	matchs="ECEARTH_SRC_DIR RUN_DIR USE_FORKING MODULE_LIST GRIBAPI_BASE_DIR"
	for match in $matchs ; do
		[[ $match == "ECEARTH_SRC_DIR" ]]  && new=${SRCDIR}
		[[ $match == "RUN_DIR" ]]  && new='${SCRATCH}/ece3/${exp_name}/run'
		[[ $match == "USE_FORKING" ]]  && new=true
		[[ $match == "MODULE_LIST" ]] && new='PrgEnv-intel cdo netcdf4/4.6.2'
		[[ $match == "GRIBAPI_BASE_DIR" ]] && new='/usr/local/apps/grib_api/1.27.0/INTEL/170'
	
		function_replacer $templatefile $match "$new"
	done

	# run ececonf
	cd $RUNDIR
	$ecconfexe -p ${platform_run} $RUNDIR/config-run.xml
fi

