#!/usr/bin/env python

# zero-order python script aimed at producing a single figure with a few useful indicators on 
# performance by EC-Earth3. It uses only the ece.info file
# PLEASE NOTE: this has been a playground to learn python, so it is BADLY coded. 
# P. Davini - CNR-ISAC (2019)


# It expects 3 arguments: ece.info file, experiment name and last year of the simulation

import datetime as dt
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.dates import  DateFormatter
import sys
import pytz

# reading arguments
print 'Number of arguments:', len(sys.argv), 'arguments.'
print 'Argument List:', str(sys.argv)
ecefile=sys.argv[1]
expname=sys.argv[2]
year_final=int(sys.argv[3])
out_file=sys.argv[4]

# setting parameters for plots
plt.rcParams['axes.grid'] = True

# loops for loading data from ece.info files
chpsy=[]
sypd=[]
time=[]
year=[]
with open(ecefile, 'r') as myfile:
    for line in myfile:
        if "CHPSY" in line:
            chpsy.append(float(line.split(' ')[7]))
            sypd.append(float(line.split(' ')[3]))
        if "Finished" in line:
	    time.append(dt.datetime.strptime(line[18:37]+' UTC', '%Y-%m-%d %H:%M:%S %Z').replace(tzinfo=pytz.UTC))
        if "leg_end_date" in line:
            year.append(float(line[26:30]))
print chpsy
print sypd
print time

# converts dates in numeric format
dates = matplotlib.dates.date2num(time)
year_start=int(np.min(year)-1)
now=dt.datetime.now().replace(tzinfo=pytz.UTC)

# set figure properties
figsize=15
fig = plt.figure(num = 1, figsize=(figsize,figsize*1.2), facecolor='w', edgecolor='k')
fig.suptitle('Basic performance indicators from experiment '+expname,fontsize=16)
#plt.subplots(3, 1, sharex='row', figsize=(13.2,13.2),facecolor='w', edgecolor='k')

# First plots walltime evolution
ax1=plt.subplot(3,1,1,title='Walltime evolution')
ax1.plot_date(year, dates, xdate=False, ydate=True, color="purple", fmt="-", linewidth=3)
ax1.set_xlim([year_start, year_final])
ax1.yaxis.set_major_formatter( DateFormatter('%Y-%m-%d') )
ax1.set_ylabel('Time')

# Linear fit to extrapolate expected simulation end
ax1.plot_date(range(year_start,year_final), np.poly1d(np.polyfit(year, dates, 1))(range(year_start,year_final)),xdate=False, ydate=True, color="purple", fmt=":", linewidth=2)
date_final=np.poly1d(np.polyfit(year, dates, 1))(year_final)
ax1.set_ylim([min(dates), date_final])
date_final_format=matplotlib.dates.num2date(date_final)

# compute length of simulation
# if simulation is over, estimate the total time that was needed
# otherwise time up to now
if max(year) == year_final :
    delta=(max(time) - min(time))
else :
    delta=now - min(time)

# days passsed and asypd
days = delta.days+delta.seconds/86400.
asypd=float(max(year) - min(year))/ days
print days
print asypd


# Linear fit to extrapolate expected simulation based on the last 5 years
year_short=year[-5:]
dates_short=dates[-5:]
ax1.plot_date(range(year_start,year_final), np.poly1d(np.polyfit(year_short, dates_short, 1))(range(year_start,year_final)),xdate=False, ydate=True, color="magenta", fmt=":", linewidth=2)
date_final_short=np.poly1d(np.polyfit(year_short, dates_short, 1))(year_final)
date_final_short_format=matplotlib.dates.num2date(date_final_short)

# Text and legend
ax1.text(0.65, 0.1,'Days since simulation started:'+str(round(days,2)),transform = ax1.transAxes, fontsize=15)
ax1.legend(['Value','Full expected end: '+date_final_format.strftime("%Y-%m-%d"),'Last 5-year expected end: '+date_final_short_format.strftime("%Y-%m-%d")],loc='upper left', shadow=True, fancybox=True)

# Second plot: CHPSY evolution
ax2=plt.subplot(3,1,2, title='CHPSY evolution')
ax2.plot(year, chpsy, color="green", linewidth=3)
ax2.set_ylabel('Core hours per simulated year')
ax2.axhline(np.mean(chpsy), color='darkgreen', linestyle=':',linewidth=2)
ax2.legend(['Value','Average: '+str(round(np.mean(chpsy),2))+u"\u00B1"+str(round(np.std(chpsy),2))],loc='upper left', shadow=True, fancybox=True)
ax2.text(0.65, 0.1,'Total consumed kh:'+str(round(np.sum(chpsy)/1000,2)),transform = ax2.transAxes, fontsize=15)

# Third plot: SYPD evolution
ax3=plt.subplot(3,1,3, title='SYPD evolution')
ax3.plot(year, sypd, color="red", linewidth=3)
ax3.set_ylabel('Simulated year per day')
ax3.axhline(np.mean(sypd), color='darkred', linestyle=':',linewidth=2)
ax3.legend(["Value","Average: "+str(round(np.mean(sypd),2))+u"\u00B1"+str(round(np.std(sypd),2))],loc='upper left', shadow=True, fancybox=True)
ax3.text(0.65, 0.1,'Estimated ASYPD:'+str(round(asypd,2)),transform = ax3.transAxes, fontsize=15)
plt.savefig(out_file, dpi=20, orientation='portrait', transparent="white")
