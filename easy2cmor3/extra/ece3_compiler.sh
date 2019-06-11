#!/bin/bash
set -e


# script to compile EC-Earth with a single command
do_svn=false
do_compile=false
do_runconfig=true
do_clean=false

# user configuration
revision=6903
platform_src=ecmwf-cca-intel-mpi
platform_run=ecmwf-cca-intel
do_lpjg=true
nemo_config=ORCA1L75_LIM3

# hard coded option
rxxxx="r$revision"
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
	svn checkout -r $revision  https://svn.ec-earth.org/ecearth3/trunk $PERM/ecearth3/revisions/$rxxxx
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
	matchs="ECEARTH_SRC_DIR RUN_DIR USE_FORKING MODULE_LIST"
	for match in $matchs ; do
		[[ $match == "ECEARTH_SRC_DIR" ]]  && new=${SRCDIR}
		[[ $match == "RUN_DIR" ]]  && new='${SCRATCH}/ece3/${exp_name}/run'
		[[ $match == "USE_FORKING" ]]  && new=true
		[[ $match == "MODULE_LIST" ]] && new='PrgEnv-intel cdo netcdf4/4.6.2'
		function_replacer $templatefile $match "$new"
	done

	# run ececonf
	cd $RUNDIR
	$ecconfexe -p ${platform_run} $RUNDIR/config-run.xml
fi

