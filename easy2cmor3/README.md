# EASY2CMOR3 package

By P. Davini (Sep 2018 - Apr 2019)
adapted from K. Strommen and Gijs van der Oord scripts 

These are series of scripts thought to provide a simplified and organized appraoch to run ECE2CMOR3 (https://github.com/goord/ece2cmor3).
Since it has been merged in to the ece3-postproc tool, it uses a configuration file that you can find in 
: ${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh

Here you can specify in there easily where your experiment is, where the output should go, the required varlist and parameter tables, the metadata, the number of processors for each process, etc
Of course the different softwares must be installed separately: they are available under conda. 

The package includes script for ece2cmor (so for the cmorization part) but also for the quality assessment (QA) part - this is mainly required only for CMIP6 data. Tools as nctime and QA-DKRZ (which must be installed separately) can be used with some of this scripts. There is also the possibility to create ad-hoc functions to correct wrong metadata with NCO. 
When the cmorization has success it produces a text filesin a specified folder which can be used to track the whole procedure. 
The metadata folder is very important, since is the folder from which the easy2cmor script takes the metadata to be applied during the cmorization. You need to create your own metadata file in order to proceed for cmorizaton. Personalized variable list (i.e. which variable you want to cmorize) can also be defined. 
The script in the folder are briefly described here below:

* 'run_1year_ece2cmor3.sh': this is the core script. It handles the submission of the job with different flags (ATM, OCE, VEG) for the different component. These call 3 different functions with uses the ece2cmor3 package. It handles also the three tools for QA (PrePARE, nctime, QA-DKRZ). PrePARE is run as a dependency following the ece2cmor scripts. It is working correctly only with PBS and it has been tuned for cca

* 'year_looper.sh': A generic wrapper function which apply the 'run_1year_ece2cmor3.sh' script to a loop of years. This is the most common way to use easy2cmor.

* 'autocmor.sh': A loop which check how many years of the experiments have been currently run and call the  'run_1year_ece2cmor3.sh' over all the missing years. Very useful during simulation operative production.

* 'ece2cmor3_updater.sh' : Basic script which fetch and pull the most recenet commit of the ece2cmor3 package from github. It also install it on the required folder and can perform installation from scratch. If you have already conda setup it could be a good way to install the ece2cmor. 

* 'check_cmor_files.sh' : given an experiment and a defined year, it compares the output produced by the cmorization with that of the varlist.json from the data request

* 'check_files_per_year.sh' : for a series of years from a given experiment, it estimates how many variables are there per year

* 'config_and_create_metadata.sh' : create metadata and varlist request extracting it from the ece2cmor3 tool and the EC-Earth repository. Quite a lot of manual adjstument is needed

* 'adjust_versions.sh' : powerful script from Uwe. Check how many versions have been produced and recreate a user-defined one. Useful when cmor data generation is going across midnight (i.e. always)

Inside the scripts folder you can find the scripts which handle the core operations:

* 'call_correct_rename.sh' : simple script that performs correction/renaming operation on wrong cmor files. You can create your own functions and call them. 
* 'call_ece2cmor3.sh': core script which is called to perform the cmorization. It is made by 3 different functions one for IFS, one for NEMO and one for LPJG
* 'call_qa-dkrz.sh': script to call the QA-DKRZ quality assurance tool (conda version)
* 'call_github-qa-dkrz.sh': same as above, but for the github installed version
* 'call_nctime.sh': script to call the nctime tool
* 'call_new-PrePARE.sh': script to call PrePARE. 
* 'call_PrePARE.sh' - deprecated




