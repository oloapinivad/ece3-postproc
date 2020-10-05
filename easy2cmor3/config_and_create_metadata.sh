# script based on ece2cmor3 to generate new metadata files for each experiment

usage()
{
   echo "Usage:"
   echo "       ./check_cmor_files.sh expname"
   echo "	EXTRA FLAGS:"
   echo "	generate=false/true to create metadata [default: false]"
   echo "	investigate=false/true to test special varlist [default: false]"

   echo
}


if [ $# -lt 1 ]; then
   usage
   exit 1
fi

expname=$1
generate=${2:-false}
investigate=${3:-false}
#reference_revision=covid19-r8037
reference_revision=r7870

case $expname in
	b025)   mip=LongRunMIP;		exptype=stabilization-ssp585-2025;   model=EC-EARTH-AOGCM; realization=1 ; table=BOTT ;;
	b050)   mip=LongRunMIP;		exptype=stabilization-ssp585-2050;   model=EC-EARTH-AOGCM; realization=1 ; table=BOTT ;;
	b100)   mip=LongRunMIP;		exptype=stabilization-ssp585-2100;   model=EC-EARTH-AOGCM; realization=1 ; table=BOTT ;;
	bot0)   mip=CMIP; 		exptype=historical;   model=EC-EARTH-AOGCM; realization=4 ; table=BOTT ;;
	chis)   mip=CMIP; 		exptype=historical;   model=EC-EARTH-AOGCM; realization=4 ; table=CMIP ;;
	caaa)   mip=CMIP;               exptype=amip; 	      model=EC-EARTH-AOGCM; realization=4 ; table=CMIP;;
	c4co)   mip=CMIP;               exptype=abrupt-4xCO2; model=EC-EARTH-AOGCM; realization=8 ; table=CMIP;;
	c119)   mip=ScenarioMIP;        exptype=ssp119;       model=EC-EARTH-AOGCM; realization=4 ; table=CMIP;;
	c126)	mip=ScenarioMIP; 	exptype=ssp126;     model=EC-EARTH-AOGCM; realization=4 ; table=CMIP;;
	c245)   mip=ScenarioMIP;        exptype=ssp245;     model=EC-EARTH-AOGCM; realization=4 ; table=CMIP;;
	c370)   mip=ScenarioMIP;        exptype=ssp370;     model=EC-EARTH-AOGCM; realization=4 ; table=CMIP ;;
	c585)   mip=ScenarioMIP;        exptype=ssp585;     model=EC-EARTH-AOGCM; realization=4 ; table=CMIP ;;
	vhis)   mip=CMIP; 		exptype=historical; model=EC-EARTH-Veg  ; realization=4 ; table=CMIP ;;
	vaaa)   mip=CMIP;               exptype=amip; 	    model=EC-EARTH-Veg  ; realization=4 ; table=CMIP ;;
	v126)   mip=ScenarioMIP;        exptype=ssp126;     model=EC-EARTH-Veg  ; realization=4 ; table=CMIP ;;
	v245)   mip=ScenarioMIP;        exptype=ssp245;     model=EC-EARTH-Veg  ; realization=4 ; table=CMIP ;;
	v370)   mip=ScenarioMIP;        exptype=ssp370;     model=EC-EARTH-Veg  ; realization=4 ; table=CMIP ;;
	v585)   mip=ScenarioMIP;        exptype=ssp585;     model=EC-EARTH-Veg  ; realization=4 ; table=CMIP ;;
	k1ct)   mip=CovidMIP;           exptype=ssp245-baseline;     model=EC-EARTH-AOGCM  ; realization=2 ; source_realization=4 ; table=CovidMIP ;;
	k1bl)   mip=CovidMIP;           exptype=ssp245-covid;     model=EC-EARTH-AOGCM  ; realization=2 ; source_realization=4 ; table=CovidMIP ;;
        llp0)   mip=REFORGE;            exptype=rfrg-ctrl-param; model=EC-EARTH-AOGCM; realization=1 ; table=RFRG ;;
	lln0)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-AOGCM; realization=1 ; table=RFRG ;;
	lln1)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-AOGCM; realization=2 ; table=RFRG ;;
	lln2)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-AOGCM; realization=3 ; table=RFRG ;;
        mmp0)   mip=REFORGE;            exptype=rfrg-ctrl-param; model=EC-EARTH-TL511; realization=1 ; table=RFRG ;;
	mmp1)   mip=REFORGE;            exptype=rfrg-ctrl-param; model=EC-EARTH-TL511; realization=2 ; table=RFRG ;;
        mmn0)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-TL511; realization=1 ; table=RFRG ;;
        mmn1)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-TL511; realization=2 ; table=RFRG ;;
        mln0)   mip=REFORGE;            exptype=rfrg-orog255-noparam; model=EC-EARTH-TL511; realization=1 ; table=RFRG;;
	mln1)   mip=REFORGE;            exptype=rfrg-orog255-noparam; model=EC-EARTH-TL511; realization=2 ; table=RFRG;;
	hhp0)   mip=REFORGE;            exptype=rfrg-ctrl-param; model=EC-EARTH-TL799; realization=1 ; table=RFRG;;
	hhn0)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-TL799; realization=1 ; table=RFRG;;
	hln0)   mip=REFORGE;            exptype=rfrg-orog255-noparam; model=EC-EARTH-TL799; realization=1 ; table=RFRG ;;
	hhn1)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-TL799; realization=2 ; table=RFRG;;
        hln1)   mip=REFORGE;            exptype=rfrg-orog255-noparam; model=EC-EARTH-TL799; realization=2 ; table=RFRG ;;
	sspn)   mip=CMIP;   		exptype=piControl-spinup ; model=EC-EARTH-SPPT; realization=1 ; table=SPPT ;;
	sctl)   mip=CMIP;               exptype=piControl ; model=EC-EARTH-SPPT; realization=1 ; table=SPPT ;;
	s4co)   mip=CMIP;               exptype=abrupt-4xCO2 ; model=EC-EARTH-SPPT; realization=1 ; table=SPPT ;
esac

# ctrl file dir
CTRLDIR=$PERM/ecearth3/revisions/${reference_revision}/runtime/classic/ctrl/cmip6-output-control-files/${table}

# autotuning of parent label
if [[ $mip == ScenarioMIP ]] ; then
	parent_realization="r4i1p1f1"
elif [[ $mip == CovidMIP ]] ; then
	if [[ $exptype == "ssp245-baseline" ]] ; then
		parent_realization="r${source_realization}i1p1f1"
	else
		parent_realization="r${realization}i1p1f2"
	fi

else 
 	parent_realization="r1i1p1f1"
fi
echo $parent_realization

[[ $exptype == amip ]] && refdate=1970-01-01 || refdate=1850-01-01

# set number of files without 
if [[ $model == "EC-EARTH-AOGCM" ]] ; then
    if [[ $mip == "CMIP" ]] ; then
	if [[ $exptype == "historical" ]] ; then
	    expected_nfile_nofx=258 
	    expected_nfile=264
	elif [[ $exptype == "amip" ]] ; then
	    expected_nfile_nofx=134
            expected_nfile=134
	elif [[ $exptype == "abrupt-4xCO2" ]] ; then
	    expected_nfile_nofx=170
            expected_nfile=175
	fi
    elif [[ $mip == "ScenarioMIP" ]] ; then
	expected_nfile_nofx=225
        expected_nfile=230
    fi
elif [[ $model == "EC-EARTH-Veg" ]] ; then
    if [[ $mip == "CMIP" ]] ; then
	if [[ $exptype == "historical" ]] ; then
	    expected_nfile_nofx=277
	    expected_nfile=283
	 elif [[ $exptype == "amip" ]] ; then
            expected_nfile_nofx=171
            expected_nfile=171
        fi
    elif [[ $mip == "ScenarioMIP" ]] ; then
        expected_nfile_nofx=275
        expected_nfile=280
    fi
elif [[ $model == "EC-EARTH-SPPT" ]] ; then
    expected_nfile_nofx=177
    expected_nfile=184
elif [[ $mip == "REFORGE" ]] ; then 
    expected_nfile_nofx=104
    expected_nfile=104
fi

echo "Config file for $expname"
echo "mip = $mip"
echo "experiment = $exptype"
echo "model configuration = $model"
echo "realization index = r$realization"
echo "reference date = $refdate"


#--------config file-----

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1

 # load utilities
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# conf file and directories
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# block that generate the metadata: it is based on the script provided in ece2cmor3 package
# an extra modification is performed to replace the needed realization index
# WORKS ONLY FOR CMIP6
if [[ $generate == true ]] ; then
	
	echo "Generating required metadata!"
	METADATADIR=${EASYDIR}/metadata

	if [[ $table == "CMIP" ]] ; then
		cd ${ECE2CMOR3DIR}/scripts/
		creator=${ECE2CMOR3DIR}/scripts/modify-metadata-template.sh
		bash $creator $mip $exptype $model
		#cd $EASYDIR
		FILEINDIR=${ECE2CMOR3DIR}/scripts
	elif [[ $table == "CovidMIP" ]] ; then
		FILEINDIR=$CTRLDIR/cmip6-experiment-${table}-${exptype}
	fi
		
	for realm in ifs nemo lpjg ; do

		filein=${FILEINDIR}/metadata-cmip6-$mip-$exptype-$model-$realm-template.json
		fileout=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-$realm-$expname.json
		echo $filein

		if [[ -f $filein ]] ;  then 
			echo "mv  $filein $fileout"
			mv  $filein $fileout
			sed -i "/realization_index/s/1/${realization}/"  $fileout
			sed -i "/parent_variant_label/s/r1i1p1f2/${parent_realization}/"  $fileout
			sed -i "/parent_variant_label/s/r1i1p1f1/${parent_realization}/"  $fileout
		fi
	done
fi

ECE3DIR=$HOME/ec-earth

# exporting values for ece2cmor runs
# set varlist
if [[ $table == "CMIP" ]] ; then
<<<<<<< HEAD
	VARLISTDIR=${CTRLDIR}/$model/cmip6-experiment-$mip-$exptype
=======
	VARLISTDIR=$ECE3DIR/revisions/${reference_revision}/runtime/classic/ctrl/cmip6-output-control-files/$mip/$model/cmip6-experiment-$mip-$exptype
>>>>>>> 202b1df61ede01346754cebdc6f66cef5b190c6b
	if [[ $investigate == false ]] ; then
		VARLIST=$VARLISTDIR/cmip6-data-request-varlist-$mip-$exptype-$model.json
	else 
		VARLIST=$EASYDIR/varlist/test-cmip6.json
	fi
elif [[ $table == "CovidMIP" ]] ; then
	VARLIST=${CTRLDIR}/cmip6-experiment-$mip-$exptype/cmip6-data-request-varlist-$mip-$exptype-$model.json
elif [[ $table == "RFRG" ]]  ; then
		VARLIST=$EASYDIR/varlist/reforge-varlist.json
		TABDIR=$PERM/ecearth3/cmorization/reforge-cmor-tables/Tables
		tabdir="--tabledir $TABDIR"
elif [[ $table == "BOTT" ]]  ; then
		VARLIST=$EASYDIR/varlist/bottino-varlist.json
		TABDIR=$HOME/post/cmorization/bottino_tables/Tables
		tabdir="--tabledir $TABDIR"
elif [[ $table == "SPPT" ]]  ; then
                VARLIST=$EASYDIR/varlist/sppt-varlist.json
		TABDIR=$PERM/ecearth3/cmorization/reforge-cmor-tables/Tables
                tabdir="--tabledir $TABDIR"
fi


#set metadata
METADATADIR=${EASYDIR}/metadata
METADATAFILEATM=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-ifs-${expname}.json
METADATAFILEOCE=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-nemo-${expname}.json
METADATAFILEVEG=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-lpjg-${expname}.json

