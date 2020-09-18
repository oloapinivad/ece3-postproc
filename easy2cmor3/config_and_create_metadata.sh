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
reference_revision=r7055

case $expname in
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
	sspn)   mip=CMIP;   		exptype=piControl-spinup ; model=EC-EARTH-SPPT; realization=1 ; table=SPPT ;;
	sctl)   mip=CMIP;               exptype=piControl ; model=EC-EARTH-SPPT; realization=1 ; table=SPPT ;;
	s4co)   mip=CMIP;               exptype=abrupt-4xCO2 ; model=EC-EARTH-SPPT; realization=1 ; table=SPPT ;
esac

[[ $mip == ScenarioMIP ]] && parent_realization=4 || parent_realization=1
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
	cd ${ECE2CMOR3DIR}/scripts/
	creator=${ECE2CMOR3DIR}/scripts/modify-metadata-template.sh
	bash $creator $mip $exptype $model
	cd $EASYDIR

	for realm in ifs nemo lpjg ; do
		filein=${ECE2CMOR3DIR}/scripts/metadata-cmip6-$mip-$exptype-$model-$realm-template.json  
		METADATADIR=${EASYDIR}/metadata
		fileout=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-$realm-$expname.json
		if [[ -f $filein ]] ;  then 
			mv  $filein $fileout
			sed -i "/realization_index/s/1/${realization}/"  $fileout
			sed -i "/parent_variant_label/s/r1/r${parent_realization}/"  $fileout
		fi
	done
fi

# exporting values for ece2cmor runs
# set varlist
if [[ $table == "CMIP" ]] ; then
	VARLISTDIR=$PERM/ecearth3/revisions/${reference_revision}/runtime/classic/ctrl/cmip6-output-control-files/$mip/$model/cmip6-experiment-$mip-$exptype
	if [[ $investigate == false ]] ; then
		VARLIST=$VARLISTDIR/cmip6-data-request-varlist-$mip-$exptype-$model.json
	else 
		VARLIST=$EASYDIR/varlist/test-cmip6.json
	fi
elif [[ $table == "RFRG" ]]  ; then
		VARLIST=$EASYDIR/varlist/reforge-varlist.json
		TABDIR=$PERM/ecearth3/cmorization/reforge-cmor-tables/Tables
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
