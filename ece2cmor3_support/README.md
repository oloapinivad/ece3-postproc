By P. Davini from K. Strommen script (Sep 2018)

These files are thought to provide wrapper scripts to run ECE2CMOR3 (https://github.com/goord/ece2cmor3)
They are added here in order to keep track of them. Clearly, you will need to install all the ece2cmor3 tool separately

There is one main script which is meant to handle the whole cmorization:

./cmorize_month.sh

This aims at cmorizing 1 month of IFS data and/or 1 year of NEMO data. 
You can specify in there easily where your experiment is, where the output should go, the required varlist and parameter tables, the metadata, etc...
Metadata, varlist and parameter tables used to cmorize PRIMAVERA data are in the subdirectories.
The script can be  run directly from terminal or launched via the other main script:

./submit_leg.sh

This is just basic wrapper for cmor_mon_filter.sh and is set up to easily launch enough jobs to process a full EC-Earth year. If it's IFS only, it launches 12 jobs, one for each month, and if coupled, it launches 13, with all of NEMO handled in one job. 
It is meant to work with SLURM since it has been developed on Marconi, so that data structure too is following CNR requirements.

Testing indicates 1 month of low-res (T255ORCA1) IFS takes around 35-40 minutes, and 1 year of low-res NEMO takes around 15 minutes.
For hi-res (T511ORCA025) 1 month IFS takes around 2h30 min hours and NEMO around 1h30. However, IFS can be parallized considerably reducing the time (15 minutes with 8 cores at T255).

Other companion scripts are present:

- ./check_cmor_files.sh

wich evalutes the difference between the data obtained by the cmorization and the request you made in your varlist.

- ./code_updater.sh

It is a trivial script aimed at pulling and installing a newer version of the ece2cmor3 tool.

- ./merge_month.sh

It breaks the directory structure but it concatenates the IFS data into a single one year file. 

- ./year_looper.sh

Zero-order looper to launch several years (using ./submit_year.sh)




