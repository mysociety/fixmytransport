#!/usr/bin/python

# A script to draw graphs showing the number of reports by transport
# type each month.  This script expects to find a file called
# 'problems.csv' in the current directory which should be generated
# by:
#       DIR=`pwd` rake data:create_problem_spreadsheet

import csv
import datetime
from collections import defaultdict

import matplotlib.pyplot as plt

import itertools

transport_types = 'Bus', 'Train', 'Tram', 'Ferry'

counts = {}
for transport_type in transport_types:
    counts[transport_type] = defaultdict(int)

today = datetime.date.today()
latest_month = earliest_month = (today.year, today.month)

maximum_count = -1

with open('problems.csv') as fp:
    reader = csv.DictReader(fp, delimiter=',', quotechar='"')
    for row in reader:
        d = datetime.datetime.strptime(row['Created'],
                                       '%H:%M %d %b %Y')
        ym = (d.year, d.month)
        earliest_month = min(earliest_month, ym)
        transport_modes = row['Transport mode']
        for transport_type in transport_types:
            if transport_type in transport_modes:
                counts[transport_type][ym] += 1
                maximum_count = max(maximum_count, counts[transport_type][ym])

def months_between(earlier, later):
    """A generator for iterating over months represented as (year, month) tuples"""
    year = earlier[0]
    month = earlier[1]
    while True:
        yield (year, month)
        if month == 12:
            year = year + 1
            month = 1
        else:
            month += 1
        if (year, month) > later:
            return

all_months = list(months_between(earliest_month, latest_month))
# Don't include the most recent month, since the data won't be
# complete:
all_months = all_months[0:-1]
months = len(all_months)

# Make sure that there's at least a zero count for each month we're
# considering:
for d in counts.values():
    for ym in all_months:
        d[ym] += 0

for transport_type in transport_types:
    fig = plt.figure()
    d = counts[transport_type]
    x = all_months
    y = [d[ym] for ym in x]
    x_labels = ["%d-%d" % ym for ym in x]
    plt.bar(range(months), y)
    plt.xticks(range(months), x_labels, size='small', rotation=60)
    plt.xlim(0, months)
    plt.ylim(0, maximum_count)
    plt.title(transport_type + ' issue report counts per month on FixMyTransport')
    plt.ylabel('Number of problems or campaigns')
    plt.savefig(transport_type.lower() + ".png", dpi=100)
