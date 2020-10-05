#/bin/bash

export PATH=/usr/local/bin:$PATH
. ~/.profile
. ~/.bashrc

explist="hhn1 hln1"
mastermind="CNR-ISAC"
transfer="ectrans"
host="wilma"

# default
DIR=$ECE3_POSTPROC_TOPDIR/performance

for exp in $explist ; do

	 # experiment details
        case $exp in
                "chis") start_year=1850; end_year=2015; exp_info="CMIP6 Historical AOGCM"; userexp=ccpd ;;
		"vhis") start_year=1850; end_year=2015; exp_info="CMIP6 Historical Veg"; userexp=ccpd ;;
		"c4co") start_year=1850; end_year=2015; exp_info="CMIP6 abrupt-4CO2 AOGCM"; userexp=ccpd ;;
		"c119") start_year=2015; end_year=2101; exp_info="CMIP6 SSP1-1.9 AOGCM"; userexp=ccpd ;;
		"c126") start_year=2015; end_year=2101; exp_info="CMIP6 SSP1-2.6 AOGCM"; userexp=ccpd ;;
		"c245") start_year=2015; end_year=2101; exp_info="CMIP6 SSP2-4.5 AOGCM"; userexp=ccpd ;;
		"c370") start_year=2015; end_year=2101; exp_info="CMIP6 SSP3-7.0 AOGCM"; userexp=ccpd ;;
		"c585") start_year=2015; end_year=2101; exp_info="CMIP6 SSP5-8.5 AOGCM"; userexp=ccpd ;;
		"v126") start_year=2015; end_year=2101; exp_info="CMIP6 SSP1-2.6 Veg"; userexp=ccpd ;;
		"v245") start_year=2015; end_year=2101; exp_info="CMIP6 SSP2-4.5 Veg"; userexp=ccpd ;;
		"v370") start_year=2015; end_year=2101; exp_info="CMIP6 SSP3-7.0 Veg"; userexp=ccpd ;;
		"v585") start_year=2015; end_year=2101; exp_info="CMIP6 SSP5-8.5 Veg"; userexp=ccpd ;;
		"caaa") start_year=1970; end_year=2018; exp_info="CMIP6 AMIP AOGCM"; userexp=ccpd ;;
		"vaaa") start_year=1970; end_year=2018; exp_info="CMIP6 AMIP Veg"; userexp=ccpd ;;
 		"sspn") start_year=1850; end_year=1900; exp_info="CMIP6 spinup SPPT"; userexp=ccpd ; project=REFORGE ;;
		"sctl") start_year=1850; end_year=2014; exp_info="CMIP6 piControl SPPT"; userexp=ccpd ; project=REFORGE ;;
		"s4co") start_year=1850; end_year=2014; exp_info="CMIP6 abrupt-4xCO2 SPPT"; userexp=ccpd ; project=REFORGE ;;
                "mmn1") start_year=1999; end_year=2030; exp_info="REFORGE T511 rfrg-ctrl-noparam"; userexp=ccpd ; project=REFORGE ;;
		"mmp1") start_year=1999; end_year=2030; exp_info="REFORGE T511 rfrg-ctrl-param"; userexp=ccpd ; project=REFORGE ;;
		"mln1") start_year=1999; end_year=2030; exp_info="REFORGE T511 rfrg-ctrl-orog255"; userexp=ccpd ; project=REFORGE ;;
		"hln1") start_year=1999; end_year=2020; exp_info="REFORGE T799 rfrg-orog255-noparam"; userexp=ccpd ; project=REFORGE ;;
                "hhn1") start_year=1999; end_year=2020; exp_info="REFORGE T799 rfrg-ctrl-noparam"; userexp=ccpd ; project=REFORGE ;;
	
        esac

	# to be looped
	SCRATCH=/lus/snx11062/scratch/ms/it/$userexp
	PERM=/perm/ms/it/$userexp

	HTML=$DIR/${exp}.index.html
	figure=$DIR/performance.${exp}.svg
	cp $DIR/monitoring.tmpl $HTML
	ecefile=$SCRATCH/ece3/$exp/ece.info
	ifslog=$SCRATCH/ece3/$exp/run/ifs.log

	exp_details="$mastermind $exp_info from $start_year up to $end_year"

	# read ece.info to extract current status
	if [[ -f $ecefile ]] ; then 
	    . $ecefile
	    run_year=$(date -u -d "${leg_end_date}" +%Y)
	else
	    echo "ece.info not there, the experiment is not yet started"
	    run_year=${start_year}
	fi
	
	# simulation
	psim=$(bc <<< "scale=2; ($run_year - $start_year) * 100 / ($end_year - $start_year)")
	ysim=$((run_year - 1))
	(( $(echo "$psim <= 0" |bc -l) )) && ysim="NA"

	#postproc: cmor
	permdir=$PERM/ecearth3/infodir
	nfiles=$( ls $permdir/cmorized/$exp/PreP*.txt| wc -l )
	ycmor=$(( $start_year + $nfiles - 1 ))
	pcmor=$(bc <<< "scale=2; ($nfiles) * 100 / ($end_year - $start_year)")
	(( $(echo "$pcmor <= 0" |bc -l) )) && ycmor="NA"

	#postproc: hiresclim	
	nfiles=$( ls $permdir/hiresclim/$exp/*.txt| wc -l )
	yhir=$(( $start_year + $nfiles - 1 )) 
        phir=$(bc <<< "scale=2; ($nfiles) * 100 / ($end_year - $start_year)")
	echo $phir
	(( $(echo "$phir <= 0" |bc -l) )) && yhir="NA"

	#average performance
	chpsy=$( cat $ecefile | grep CHPSY | awk -F " " '{ count++ ; pippo+=$6 } END {print pippo/count; }' )
	sypd=$( cat $ecefile | grep CHPSY | awk -F " " '{ count++ ; pippo+=$4 } END {print pippo/count; }' )

	# replace all you need
	sed -i "s/-EXPNAME-/$exp/g" $HTML
	sed -i "s/-EXPDETAILS-/$exp_details/g" $HTML
	sed -i "s/-PSIM-/$psim/g" $HTML
	sed -i "s/-PCMOR-/$pcmor/g" $HTML
	sed -i "s/-PHIR-/$phir/g" $HTML
	sed -i "s/-YSIM-/$ysim/g" $HTML
        sed -i "s/-YCMOR-/$ycmor/g" $HTML
        sed -i "s/-YHIR-/$yhir/g" $HTML
	sed -i "s/-DATE-/$(date)/g" $HTML
	sed -i "s/-CHPSY-/$chpsy/g" $HTML
	sed -i "s/-SYPD-/$sypd/g" $HTML

	# loop on archive properties, estimate status and replace
	for kind in output rest cmor logfiles init postcheck ; do
		nfiles=$( ls $permdir/archive/$exp/*$kind*.txt| wc -l )
		yrun=$(( $start_year + $nfiles - 1 ))
		prun=$(bc <<< "scale=2; ($nfiles) * 100 / ($end_year - $start_year)")
		(( $(echo "$prun <= 0" |bc -l) )) && yrun="NA"

		case $kind in 
			"output") KKK=YAOUT; JJJ=PAOUT ;;
			"rest") KKK=YARES; JJJ=PARES ;;
			"cmor") KKK=YACMOR; JJJ=PACMOR ;;
			"logfiles") KKK=YALOG; JJJ=PALOG ;;
			"init") KKK=YAINIT; JJJ=PAINIT ;;
			"postcheck") KKK=YAPOST; JJJ=PAPOST ;;
		esac
		sed -i "s/-$KKK-/$yrun/g" $HTML
		sed -i "s/-$JJJ-/$prun/g" $HTML
	done

	# check status of the simulation and update html
	# ifs_status: tail ifs.log, grep date, replaces multiples spaces and trim leading one and put in lower case
	# fun single line excercise with grep, tail, sed, awk and tr
	ifs_status=$(tail -n100 $ifslog | grep " DATE= " | tail -n1 | sed "s/  \+/ /g" | awk '{$1=$1};1' | tr '[:upper:]' '[:lower:]')
	# grep status from qstat
	check_status=$(qstat -s -u $USER | grep "${exp}.job")
	# according to the status update the templates with different values and colors
	[[ -z ${check_status} ]] && { model_status="not running" ; col_status="red" ; }
	[[ $(echo ${check_status} | grep R ) ]] && { model_status="running (${ifs_status})"; col_status="green" ; }
	[[ $(echo ${check_status} | grep Q ) ]] && { model_status="queuing"; col_status="amber" ; }
	[[ $(echo ${check_status} | grep H ) ]] && { model_status="on hold"; col_status="red" ; }
	[[ ${run_year} -eq ${end_year} ]] && { model_status="completed!"; col_status="blue" ; }
	sed -i "s/-STATUS-/${model_status}/g" $HTML
	sed -i "s/-COLSTATUS-/${col_status}/g" $HTML
        sed -i "s/-PROJECT-/${project}/g" $HTML

	# run performance python script
	python $DIR/performance.py $ecefile $exp $end_year $figure

	# pack infodir 
	infocmor=infocmor-${exp}.tar.gz
	infocmordir=$permdir/cmorized
        tar cfvz $infocmor -C ${infocmordir} $exp

	# if ectrans is set, transfer the data
	if [[ $transfer == "ectrans" ]] ; then
		ectrans -remote $host -source $HTML -verbose -overwrite
		ectrans -remote $host -source $figure -verbose -overwrite
		ectrans -remote $host -source $infocmor -verbose -overwrite
		
		rm -f $HTML $figure $infocmor
	fi
done

