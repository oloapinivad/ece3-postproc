#!/usr/bin/env bash

set -eu

usage() {
    cat << EOT >&2
$(basename $0): Count the number of cmorised files per year.

Usage: $(basename $0) FIRST_YEAR LAST_YEAR EXPNAME

EOT
}

error() {
    usage
    echo "ERROR: $1" >&2
    [ -z ${2+x} ] && exit 99
    exit $2
}

(( $# != 3 )) && error "$(basename $0) needs exactly 3 arguments"

# set arguments

first_year=$2
last_year=$3
expname=$1

#--------config file-----

# check environment
[[ -z "${ECE3_POSTPROC_TOPDIR:-}" ]] && echo "User environment ECE3_POSTPROC_TOPDIR not set. See ../README." && exit 1

 # load utilities
. ${ECE3_POSTPROC_TOPDIR}/functions.sh
check_environment

# conf file and directories
. ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

# configurator
. ${EASYDIR}/config_and_create_metadata.sh $expname

#-------run script------

set +u
(( "$first_year" < "$last_year" )) || \
    error "First two arguments do not specify a time range: \"$first_year\" \"$last_year\""
set -u
#[ ! -d "$directory" ] && error "Third argument is not a directory: \"$directory\""

for year in $(seq $first_year $last_year)
do
    # set cmordir
    CMORDIR=$(eval echo ${ECE3_POSTPROC_CMORDIR})
    echo -n "Year $year: "
    nfiles=$( find $CMORDIR -type f -name "*_${year}*.nc" | wc -l )	
    echo $nfiles
    # security check
    if [[ $nfiles != $expected_nfile_nofx ]] ; then
	echo "WTF!!"
    fi
done


