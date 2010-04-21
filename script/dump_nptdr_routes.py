#!/usr/bin/python
#
# dump_nptdr_routes.py: Convert NPTDR data in ATCO-CIF format into CSV files that relate routes
# to locations. 
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: louise@mysociety.org; WWW: http://www.mysociety.org/
#
import optparse
import sys
import re
import os
import glob
import datetime
import time
import mx.DateTime
import csv

sys.path.extend(["../commonlib/pylib"])
import mysociety.config
import mysociety.atcocif
mysociety.config.set_file("../conf/general")

###############################################################################
# Read parameters

parser = optparse.OptionParser()

parser.set_usage('''
./dump_nptdr_routes.py [PARAMETERS]

Dump data on NPDTR routes, operators and locations. Reads ATCO-CIF timetable files.
Outputs a CSV file per subdirectory of the parent directory specified.

Examples
--datadir="October 2008/Timetable Data/CIF/ --datavalidfrom="6 Oct 2008" --datavalidto="12 Oct 2008"  
''')

parser.add_option('--datadir', type='string', dest="datadir", help='parent directory of ATCO-CIF files containing timetables to use.')
parser.add_option('--outdir', type='string', dest="outdir", help='directory for output files.')
parser.add_option('--datavalidfrom', type='string', dest="data_valid_from", help='Date range we know the data is good for')
parser.add_option('--datavalidto', type='string', dest="data_valid_to", help='Date range we know the data is good for')

(options, args) = parser.parse_args()

# Required parameters
if not options.outdir:
    raise "--outdir required"
if not options.datadir:
    raise "--datadir required"
data_valid_from = datetime.datetime.fromtimestamp(mx.DateTime.DateTimeFrom(options.data_valid_from)).date()
data_valid_to = datetime.datetime.fromtimestamp(mx.DateTime.DateTimeFrom(options.data_valid_to)).date()

def setup_atco():
    atco = mysociety.atcocif.ATCO()
    atco.restrict_to_date_range(data_valid_from, data_valid_to)
    atco.register_line_patches({
        # ATCO_NATIONAL_BUS.CIF doesn't have the grid reference for Victoria Coach Station
        "QBN000000002541                London Victoria Co                              " :
        "QBN000000002541528536  178768  London Victoria Co                              ",

        # Caythorpe in Lincolnshire doesn't have coordinate
        "QBN000000023750                Caythorpe                                       " :
        "QBN000000023750493907  347547  Caythorpe                                       "
    })

    atco.register_locations_to_ignore( [
        # stops which just indicate "Destinations vary depending on bookings" in Lincolnshire, area 270
        '000000016575',
        '000000016581',
        '000000016577',
        '000000016574',
        '000000016580',
        '000000016579',
        '000000016578',
        '000000016582',
        '000000016583',
        '000000016584',
        '000000023685',
        '000000023708',
        '000000023748',
        '000000023749',
        # appears in Lincolnshire files, area 270, for long distance bus from
        # Victoria, but has no coordinates. Is near Victoria anyway.
        '000000004387',
        '000000003300',
        '000000002403',
        '000000002805',
    ])
    return atco
    
def vehicle_code_from_filename(filepath):
    basename, ext = os.path.splitext(filepath)
    name_parts = basename.split("_")
    name_mappings = { "BUS"  : 'B',
                      "COACH": 'C',
                      "FERRY": 'F',
                      "AIR"  : 'A', 
                      "TRAIN": 'T', 
                      "METRO": 'M' }
    return name_mappings[name_parts[-1]]

subdirs = [name for name in os.listdir(options.datadir) if os.path.isdir(os.path.join(options.datadir, name))]
for subdir in subdirs:
    atco = setup_atco()      
    route_locations = {}
    nptdr_files = glob.glob(os.path.join(options.datadir, subdir, "*.CIF"))
    outfilepath = os.path.join(options.outdir, "%s.tsv" % subdir)
    if os.path.exists(outfilepath):
      continue  
    outfile = csv.writer(open(outfilepath, 'w'), delimiter="\t", quotechar='"', quoting=csv.QUOTE_MINIMAL) 
    outfile.writerow(['Vehicle Code', 'Route Number', 'Operator Code', 'Default Vehicle Code', 'Locations'])
    for filepath in nptdr_files:
        atco.read(filepath)    
        for journey in atco.journeys:
            assert journey.transaction_type == 'N'
            if journey.vehicle_type != '':
                vehicle_code = journey.vehicle_code(atco)
                default_code = False
            else:
                vehicle_code = vehicle_code_from_filename(filepath)
                default_code = True
            identifier = journey.route_number + vehicle_code + journey.operator
            locations = []
            for hop in journey.hops:
                locations.append(hop.location)
            if not locations in route_locations.setdefault(identifier, []):
                route_locations[identifier].append(locations)
                outfile.writerow([vehicle_code, journey.route_number, journey.operator, default_code, ','.join(locations)])
         