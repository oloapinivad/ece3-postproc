""" The purpose of this function is to count the number of variables 
listed in a certain control file in order to check that all the variables
are correctly cmorized. Please edit the `path` variable as required. """

import json

path = '/perm/ms/it/cc1f/ecearth3/revisions/r8095/runtime/classic/ctrl/cmip6-output-control-files-pextra/CMIP/EC-EARTH-AOGCM/cmip6-experiment-CMIP-1pctCO2-dynvar/cmip6-data-request-varlist-CMIP-1pctCO2-dynvar-EC-EARTH-AOGCM.json'
path = '/perm/ms/it/cc1f/ecearth3/revisions/r8095/runtime/classic/ctrl/cmip6-output-control-files/CMIP/EC-EARTH-AOGCM/cmip6-experiment-CMIP-abrupt-4xCO2/cmip6-data-request-varlist-CMIP-abrupt-4xCO2-EC-EARTH-AOGCM.json'

tjson = open(path)
data = json.load(tjson)

fvar = 0 # fixed
nvar = 0 # all

print('')
print('Starting count:')

for ival in range(len(data.values())):
    for jlist in range(len(data.values()[ival].values())):
        print(data.values()[ival].keys()[jlist],data.values()[ival].values()[jlist])
        if data.values()[ival].keys()[jlist][-2:] == 'fx':
            fvar += len(data.values()[ival].values()[jlist])
        nvar += len(data.values()[ival].values()[jlist])

print('%i variables are listed in the target .json file' % nvar)
print('%i variables are fixed' % fvar)
print('')

