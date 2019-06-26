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



case $expname in
	chis)   mip=CMIP; 		exptype=historical; model=EC-EARTH-AOGCM; realization=4 ;;
	c126)	mip=ScenarioMIP; 	exptype=ssp126;     model=EC-EARTH-AOGCM; realization=4 ;;
	vhis)   mip=CMIP; 		exptype=historical; model=EC-EARTH-Veg  ; realization=4 ;;
	*)      mip=CMIP; 		exptype=historical; model=EC-EARTH-AOGCM; realization=4 ;;
esac

echo "Config file for $expname"
echo "mip = $mip"
echo "experiment = $exptype"
echo "model configuration = $model"
echo "realization index = r$realization"


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
		[[ -f $filein ]] && mv $filein $fileout
		sed -i "/realization/s/1/$realization/"  $fileout
	done
fi

# exporting values for ece2cmor runs
# set varlist
VARLISTDIR=$PERM/ecearth3/revisions/r6970/runtime/classic/ctrl/cmip6-output-control-files/$mip/$model/cmip6-experiment-$mip-$exptype
if [[ $investigate == false ]] ; then
	VARLIST=$VARLISTDIR/cmip6-data-request-varlist-$mip-$exptype-$model.json
else 
	VARLIST=$EASYDIR/varlist/test-cmip6.json
fi

#set metadata
METADATADIR=${EASYDIR}/metadata
METADATAFILEATM=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-ifs-${expname}.json
METADATAFILEOCE=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-nemo-${expname}.json
METADATAFILEVEG=${METADATADIR}/metadata-cmip6-$mip-$exptype-$model-lpjg-${expname}.json

