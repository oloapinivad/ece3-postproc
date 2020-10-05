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
year_final=sys.argv[3]
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
            year.append(dt.datetime.strptime(line[19:30], '%d %b %Y').replace(tzinfo=pytz.UTC))
print chpsy
print sypd
print year
print time

# converts dates in numeric format
dates = matplotlib.dates.date2num(time)
years = matplotlib.dates.date2num(year)
print dates
print years
year_zero=(year[0].strftime("%Y"))
print year_zero
years_start=int(matplotlib.dates.date2num(dt.datetime.strptime(year_zero+'-01-01', '%Y-%m-%d')))
years_final=int(matplotlib.dates.date2num(dt.datetime.strptime(year_final+'-01-01', '%Y-%m-%d')))
print years_start
print years_final
now=dt.datetime.now().replace(tzinfo=pytz.UTC)


# set figure properties
figsize=15
fig = plt.figure(num = 1, figsize=(figsize,figsize*1.2), facecolor='w', edgecolor='k')
fig.suptitle('Basic performance indicators from experiment '+expname,fontsize=16)
#plt.subplots(3, 1, sharex='row', figsize=(13.2,13.2),facecolor='w', edgecolor='k')

# First plots walltime evolution
ax1=plt.subplot(3,1,1,title='Walltime evolution')
ax1.plot_date(years, dates, xdate=True, ydate=True, color="purple", fmt="-", linewidth=3)
ax1.set_xlim([years_start, years_final])
ax1.yaxis.set_major_formatter( DateFormatter('%Y-%m-%d') )
ax1.set_ylabel('Time')

# Linear fit to extrapolate expected simulation end
ax1.plot_date(range(years_start,years_final), np.poly1d(np.polyfit(years, dates, 1))(range(years_start,years_final)),xdate=True, ydate=True, color="purple", fmt=":", linewidth=2)
date_final=np.poly1d(np.polyfit(years, dates, 1))(years_final)
ax1.set_ylim([min(dates), date_final])
date_final_format=matplotlib.dates.num2date(date_final)

# compute length of simulation
# if simulation is over, estimate the total time that was needed
# otherwise time up to now
if max(years) == years_final :
    delta=(max(time) - min(time))
else :
    delta=now - min(time)

# days passsed and asypd
days = delta.days+delta.seconds/86400.
asypd=float(max(years) - min(years))/365.25/ days
print days
print asypd

# totla number of core hours consumed (kh)
totch = np.sum(np.diff(np.append(years_start, years)) * chpsy / 365.25) / 1000
print totch


# Linear fit to extrapolate expected simulation based on the last 5 years
years_short=years[-5:]
dates_short=dates[-5:]
ax1.plot_date(range(years_start,years_final), np.poly1d(np.polyfit(years_short, dates_short, 1))(range(years_start,years_final)),xdate=True, ydate=True, color="magenta", fmt=":", linewidth=2)
date_final_short=np.poly1d(np.polyfit(years_short, dates_short, 1))(years_final)
date_final_short_format=matplotlib.dates.num2date(date_final_short)

# Text and legend
ax1.text(0.65, 0.1,'Days since simulation started:'+str(round(days,2)),transform = ax1.transAxes, fontsize=15)
ax1.legend(['Value','Full expected end: '+date_final_format.strftime("%Y-%m-%d"),'Last 5-year expected end: '+date_final_short_format.strftime("%Y-%m-%d")],loc='upper left', shadow=True, fancybox=True)

# Second plot: CHPSY evolution
ax2=plt.subplot(3,1,2, title='CHPSY evolution')
ax2.plot_date(years, chpsy, xdate=True, ydate=False, color="green", fmt="-", linewidth=3)
ax2.set_ylabel('Core hours per simulated year')
ax2.axhline(np.mean(chpsy), color='darkgreen', linestyle=':',linewidth=2)
ax2.legend(['Value','Average: '+str(round(np.mean(chpsy),2))+u"\u00B1"+str(round(np.std(chpsy),2))],loc='upper left', shadow=True, fancybox=True)
ax2.text(0.65, 0.1,'Total consumed kh:'+str(round(totch,2)),transform = ax2.transAxes, fontsize=15)

# Third plot: SYPD evolution
ax3=plt.subplot(3,1,3, title='SYPD evolution')
ax3.plot_date(years, sypd, xdate=True, ydate=False, color="red", linewidth=3, fmt="-")
ax3.set_ylabel('Simulated year per day')
ax3.axhline(np.mean(sypd), color='darkred', linestyle=':',linewidth=2)
ax3.legend(["Value","Average: "+str(round(np.mean(sypd),2))+u"\u00B1"+str(round(np.std(sypd),2))],loc='upper left', shadow=True, fancybox=True)
ax3.text(0.65, 0.1,'Estimated ASYPD:'+str(round(asypd,2)),transform = ax3.transAxes, fontsize=15)
plt.savefig(out_file, dpi=20, orientation='portrait', transparent="white")

