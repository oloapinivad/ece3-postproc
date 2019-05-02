# EASY2CMOR3 package

By P. Davini (Sep 2018 - Apr 2019)
adapted from K. Strommen and Gijs van der Oord scripts 

These are series of scripts thought to provide a simplified and organized appraoch to run ECE2CMOR3 (https://github.com/goord/ece2cmor3).
Since it has been merged in to the ece3-postproc tool, it uses a configuration file that you can find in '${ECE3_POSTPROC_TOPDIR}/conf/${ECE3_POSTPROC_MACHINE}/conf_easy2cmor3_${ECE3_POSTPROC_MACHINE}.sh'
Here you can specify in there easily where your experiment is, where the output should go, the required varlist and parameter tables, the metadata, etc

There is one main script which is meant to handle the whole cmorization:

**./submit_year.sh**: it is a wrapper of for different scripts, which provides the cmorization of IFS and NEMO separately, the merging into yearly files and the validation of the results. If it's IFS only, it launches 12 jobs, one for each month, and if coupled, it launches 13, with all of NEMO handled in one job. Two other extra jobs are added, one for merging and one for validation. The two latter jobs are delayed in order to account for the termination of the other jobs.
It is meant to work with SLURM and PBS since it has been developed on Marconi/Galileo and on CCA, so that data structure too is following CNR requirements.

The 3 scripts called by the wrapper are: 
1.  **./cmorize_month.sh**: it aims at cmorizing 1 month of IFS data and/or 1 year of NEMO data. 
Metadata, varlist and parameter tables used to cmorize PRIMAVERA data are in the subdirectories.
Testing indicates 1 month of low-res (T255ORCA1) IFS takes around 35-40 minutes, and 1 year of low-res NEMO takes around 15 minutes. For hi-res (T511ORCA025) 1 month IFS takes around 2h30 min hours and NEMO around 1h30. However, IFS can be parallized considerably reducing the time (15 minutes with 8 cores at T255).

2. **/merge_month.sh** : It breaks the directory structure but it concatenates the IFS data into a single one year file using NCO. For hi-res it takes about 30 minutes with 24 cores (it can be heavily parallelized)

3. **./validate.sh** : It uses the Jon Seddon validation tool (that should be installed separately, https://github.com/jonseddon/primavera-val) to check data integrity. Best way to install the tool is make use of conda creating an environment called `validate`. The command is: '$ conda create -n validate -c conda-forge iris '. It takes about 1 hour at low-res and 4-5 hours at hi-res (no parallelization is available).

Finally, Other companion perhaps useful scripts are present:

- ./check_cmor_files.sh

It evalutes the difference between the data obtained by the cmorization and the request you made in your varlist

- ./code_updater.sh

It is a trivial script aimed at pulling and installing a newer version of the ece2cmor3 tool

- ./year_looper.sh

Zero-order looper to launch several years (using ./submit_year.sh)

- ./autocmor.sh

Tries to diagnose if cmorization has been completed for a single experiments and launch missing years. Useful for automation into running simulations. 

- ./correct_rename.sh

Run a loop on years in order to rename and/or update metadata when a posteriori correction is required.



