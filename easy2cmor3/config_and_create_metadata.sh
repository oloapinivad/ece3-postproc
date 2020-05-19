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
	chis)   mip=CMIP; 		exptype=historical;   model=EC-EARTH-AOGCM; realization=4 ;;
	caaa)   mip=CMIP;               exptype=amip; 	      model=EC-EARTH-AOGCM; realization=4 ;;
	c4co)   mip=CMIP;               exptype=abrupt-4xCO2; model=EC-EARTH-AOGCM; realization=8 ;;
	c119)   mip=ScenarioMIP;        exptype=ssp119;       model=EC-EARTH-AOGCM; realization=4 ;;
	c126)	mip=ScenarioMIP; 	exptype=ssp126;     model=EC-EARTH-AOGCM; realization=4 ;;
	c245)   mip=ScenarioMIP;        exptype=ssp245;     model=EC-EARTH-AOGCM; realization=4 ;;
	c370)   mip=ScenarioMIP;        exptype=ssp370;     model=EC-EARTH-AOGCM; realization=4 ;;
	c585)   mip=ScenarioMIP;        exptype=ssp585;     model=EC-EARTH-AOGCM; realization=4 ;;
	vhis)   mip=CMIP; 		exptype=historical; model=EC-EARTH-Veg  ; realization=4 ;;
	vaaa)   mip=CMIP;               exptype=amip; 	    model=EC-EARTH-Veg  ; realization=4 ;;
	v126)   mip=ScenarioMIP;        exptype=ssp126;     model=EC-EARTH-Veg  ; realization=4 ;;
	v245)   mip=ScenarioMIP;        exptype=ssp245;     model=EC-EARTH-Veg  ; realization=4 ;;
	v370)   mip=ScenarioMIP;        exptype=ssp370;     model=EC-EARTH-Veg  ; realization=4 ;;
	v585)   mip=ScenarioMIP;        exptype=ssp585;     model=EC-EARTH-Veg  ; realization=4 ;;
        llp0)   mip=REFORGE;            exptype=rfrg-ctrl-param; model=EC-EARTH-AOGCM; realization=1 ;;
	lln0)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-AOGCM; realization=1 ;;
	lln1)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-AOGCM; realization=2 ;;
	lln2)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-AOGCM; realization=3 ;;
        mmp0)   mip=REFORGE;            exptype=rfrg-ctrl-param; model=EC-EARTH-TL511; realization=1 ;;
        mmn0)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-TL511; realization=1 ;;
        mln0)   mip=REFORGE;            exptype=rfrg-orog255-noparam; model=EC-EARTH-TL511; realization=1 ;;
	hhp0)   mip=REFORGE;            exptype=rfrg-ctrl-param; model=EC-EARTH-TL799; realization=1 ;;
	hhn0)   mip=REFORGE;            exptype=rfrg-ctrl-noparam; model=EC-EARTH-TL799; realization=1 ;;
	hln0)   mip=REFORGE;            exptype=rfrg-orog255-noparam; model=EC-EARTH-TL799; realization=1 ;;
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
if [[ $mip == "CMIP" ]] || [[ $mip == "ScenarioMIP" ]] ; then
	VARLISTDIR=$PERM/ecearth3/revisions/${reference_revision}/runtime/classic/ctrl/cmip6-output-control-files/$mip/$model/cmip6-experiment-$mip-$exptype
	if [[ $investigate == false ]] ; then
		VARLIST=$VARLISTDIR/cmip6-data-request-varlist-$mip-$exptype-$model.json
	else 
		VARLIST=$EASYDIR/varlist/test-cmip6.json
	fi
elif [[ $mip == "REFORGE" ]] ; then
		VARLIST=$EASYDIR/varlist/reforge-varlist.json
		tabdir="--tabledir $PERM/ecearth3/cmorization/reforge-cmor-tables/Tables"
fi

#set metadata
METADATADIR=${EASYDIR}/metadata
METADATAFILEATM=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-ifs-${expname}.json
METADATAFILEOCE=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-nemo-${expname}.json
METADATAFILEVEG=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-lpjg-${expname}.json

