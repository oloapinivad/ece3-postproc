#!/bin/bash
set -e
set -xuve
 ############################################
 # To be called from ../master_hiresclim.sh #
 ############################################

expname=$1
year=$2
yref=$3

#usage
if [ $# -lt 3 ]
then
  echo "Usage:   ./ifs_monthly_mma.sh EXP YEAR YREF"
  echo "Example: ./ifs_monthly_mma.sh io01 1990 1990"
  exit 1
fi

# temp working dir, within $TMPDIR so it is automatically removed
mkdir -p $SCRATCH/tmp_ecearth3/tmp
WRKDIR=$(mktemp -d $SCRATCH/tmp_ecearth3/tmp/hireclim2_${expname}_XXXXXX) # use template if debugging
cd $WRKDIR

NPROCS=${IFS_NPROCS:-1}

# update IFSRESULTS and get OUTDIR0
eval_dirs 1

# where to save (archive) the results
OUTDIR=$OUTDIR0/mon/Post_$year
mkdir -p $OUTDIR || exit -1

echo "*II* --- Analyzing monthly output -----"
echo "*II* Temporary directory is $WRKDIR"
echo "*II* Data directory is $IFSRESULTS"
echo "*II* Postprocessing with $NPROCS cores"
echo "*II* Postprocessed data directory is $OUTDIR"

# output filename root
out=$OUTDIR/${expname}_${year}

#TODO if running on BSC FAT nodes after TRANSFER, untar MMA* files, change IFSRESULTS and modify gunzip
#for f in $IFSRESULTS/MMA_${expname}_????????_fc*_${year}????-${year}????.tar ; do tar xvf $f ; done

# ICMSH
    for m1 in $(seq 1 $NPROCS 12)
    do
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            eval_dirs $m  
            gunzip -c  $IFSRESULTS/MMA_${expname}_6h_SH_${ym}.nc.gz > MMA_${expname}_6h_SH_${ym}.nc
            $cdo -b F64 splitvar -sp2gpl \
                -setdate,$year-$m-01 -settime,00:00:00 -timmean \
                MMA_${expname}_6h_SH_${ym}.nc icmsh_${ym}_ &
        done
        wait
    done

# comment lnsp if running on old MMA files
for v2 in t u v z #lnsp
do
#   v1="${v2^^}"
   v1=`echo "$v2" | tr '[:lower:]' '[:upper:]'`
   rm -f ${out}_${v2}.nc
   $cdozip -r -R chname,${v1},${v2} -cat "icmsh_${year}??_${v1}.nc" ${out}_${v2}.nc
done

#part on surface pressure
if [[ -f ${out}_lnsp.nc ]] ; then
    $cdo chcode,152,134 ${out}_lnsp.nc temp_lnsp.nc
    $cdo -t $ecearth_table exp temp_lnsp.nc ${out}_sp.nc
    rm temp_lnsp.nc
fi

# ICMGG
    for m1 in $(seq 1 $NPROCS 12)
    do
        for m in $(seq $m1 $((m1+NPROCS-1)) )
        do
            ym=$(printf %04d%02d $year $m)
            eval_dirs $m  
            gunzip -c  $IFSRESULTS/MMA_${expname}_6h_GG_${ym}.nc.gz > MMA_${expname}_6h_GG_${ym}.nc
            $cdo -b F64 setdate,$year-$m-01 -settime,00:00:00 -timmean -delvar,LSM,Z \
                MMA_${expname}_6h_GG_${ym}.nc icmgg_${ym}.nc &
        done
        wait
    done

    rm -f icmgg_${year}.nc
    $cdo cat icmgg_${year}??.nc icmgg_${year}.nc
    rm -f icmgg_${year}??.nc


# these vars must be renamed
vars1=(U10M V10M T2M D2M var78 var79)
vars2=(uas vas tas tds tclw tciw)
for (( i = 0 ; i < ${#vars1[@]} ; i++ )) 
do
   ncrename -v .${vars1[$i]},${vars2[$i]} icmgg_${year}.nc
done

#these vars must be converted to lower case
vars2="ci sstk sd tcc lcc mcc hcc tcwv msl q fal ro sf lsp cp e ssr str sshf ssrd strd slhf tsr ttr ewss nsss ssrc strc stl1 ttrc tsrc"
for v2 in $vars2
do
   ncrename -v .${v2^^},$v2 icmgg_${year}.nc
done


# extract variables which do not require any calculations
$cdozip -r -R splitvar \
   -selvar,uas,vas,tas,ci,sstk,sd,tds,tcc,lcc,mcc,hcc,tclw,tciw,tcwv,msl,q,fal,stl1 \
   icmgg_${year}.nc ${out}_

# post-processing timestep in seconds
# pptime cannot be determined from the MMA files and must be set manually
# ET TODO find a way to specify pptime when needed, for now it is hard-coded
pptime=21600 #6h, default
#pptime=10800 #3h, e.g. PRIMAVERA

echo Timestep is $pptime

# precip and evap and runoff in kg m-2 s-1
$cdozip -R -r mulc,1000 -divc,$pptime -selvar,ro \
   icmgg_${year}.nc ${out}_ro.nc
$cdozip -R -r mulc,1000 -divc,$pptime -selvar,sf \
   icmgg_${year}.nc ${out}_sf.nc
$cdo expr,"totp=1000*(lsp+cp)/$pptime" \
   icmgg_${year}.nc tmp_totp.nc
$cdozip -r -R copy tmp_totp.nc ${out}_totp.nc

#$cdozip -r -R mulc,1000 -divc,$pptime -selvar,e \
#   icmgg_${year}.nc ${out}_e.nc
$cdozip -r -R splitvar -mulc,1000 -divc,$pptime \
 -selvar,e,lsp,cp icmgg_${year}.nc ${out}_
$cdo -R fldmean \
   -expr,"pme=1000*(lsp+cp+e)/$pptime" icmgg_${year}.nc tmp_pme.nc
$cdozip -r copy tmp_pme.nc ${out}_pme.nc

# divide fluxes by PP timestep
$cdozip -r -R splitvar -divc,$pptime \
   -selvar,ssr,str,sshf,ssrd,strd,slhf,tsr,ttr,ewss,nsss,ssrc,strc,tsrc,ttrc \
   icmgg_${year}.nc ${out}_

# net SFC and TOA fluxes
$cdo -R fldmean \
   -expr,"snr=(ssr+str+slhf+sshf)/$pptime" icmgg_${year}.nc tmp_snr.nc
$cdozip -r copy tmp_snr.nc ${out}_snr.nc
$cdo -R fldmean \
   -expr,"tnr=(tsr+ttr)/$pptime" icmgg_${year}.nc tmp_tnr.nc
$cdozip -r copy tmp_tnr.nc ${out}_tnr.nc

# change file suffices
( cd $OUTDIR ; for f in $(ls *.nc4); do mv $f ${f/.nc4/.nc}; done )

# fix units, ugly hack
for v in ci fal tcc lcc mcc hcc ; do ncatted -a units,${v},c,c,'0-1' ${out}_${v}.nc ; done
for v in e lsp cp ro sf ; do ncatted -a units,${v},m,c,'kg m-2 s-1' ${out}_${v}.nc ; done
for v in pme totp ; do ncatted -a units,${v},c,c,'kg m-2 s-1' ${out}_${v}.nc ; done
for v in ewss nsss ; do ncatted -a units,${v},m,c,'N m-2' ${out}_${v}.nc ; done
for v in sd ; do ncatted -a units,${v},c,c,'m' ${out}_${v}.nc ; done
for v in ssr str sshf ssrd strd slhf tsr ttr ssrc strc tsrc ttrc ; do \
    ncatted -a units,${v},m,c,'W m-2' ${out}_${v}.nc ; done
for v in snr tnr ; do ncatted -a units,${v},c,c,'W m-2' ${out}_${v}.nc ; done
for v in tclw tciw ; do ncatted -a units,${v},c,c,'kg m-2' ${out}_${v}.nc ; done
for v in tcwv ; do ncatted -a units,${v},m,c,'kg m-2' ${out}_${v}.nc ; done

# fix long_name
for v in pme totp ; do ncatted -a long_name,${v},c,c,'Total precipitation' ${out}_${v}.nc ; done

set -x
ls -l $WRKDIR
rm $WRKDIR/*.nc
cd -
rmdir $WRKDIR
set +x
