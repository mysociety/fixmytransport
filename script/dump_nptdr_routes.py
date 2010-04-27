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
./dump_nptdr_routes.py [PARAMETERS] [COMMAND]

Dump data on NPDTR routes, operators and locations. Reads ATCO-CIF timetable files.
Outputs a CSV file per subdirectory of the parent directory specified. 

Commands
routes - Dump a CSV file of route data
stops - Dump a CSV file of stop data

Examples
--datadir="October 2008/Timetable Data/CIF/ --outdir="../output" --datavalidfrom="6 Oct 2008" --datavalidto="12 Oct 2008" routes  
''')

parser.add_option('--datadir', type='string', dest="datadir", help='parent directory of ATCO-CIF files containing timetables to use.')
parser.add_option('--outdir', type='string', dest="outdir", help='directory for output files.')
parser.add_option('--datavalidfrom', type='string', dest="data_valid_from", help='Date range we know the data is good for')
parser.add_option('--datavalidto', type='string', dest="data_valid_to", help='Date range we know the data is good for')
parser.add_option('--stopcodefile', type='string', dest="stop_code_mapping_file",  default=None, help='File containing mappings from old to new ATCO codes')

(options, args) = parser.parse_args()

# Work out command
if len(args) > 1:
    raise Exception, 'Give at most one command'
if len(args) == 0:
    args = ['stops']
command = args[0]
if command not in ['stops', 'routes']:
    raise Exception, 'Unknown command'

# Required parameters
if not options.outdir:
    raise "--outdir required"
if not options.datadir:
    raise "--datadir required"
data_valid_from = datetime.datetime.fromtimestamp(mx.DateTime.DateTimeFrom(options.data_valid_from)).date()
data_valid_to = datetime.datetime.fromtimestamp(mx.DateTime.DateTimeFrom(options.data_valid_to)).date()

class CSVDumpATCO(mysociety.atcocif.ATCO):
    def __init__(self, nptdr_files, outfilepath, stop_code_mapping_file, show_progress = True):
        self.nptdr_files = nptdr_files
        self.assume_no_holidays = True
        self.show_progress = show_progress
        self.outfilepath = outfilepath
        self.vehicle_type_to_code = {}
        self.stops_dumped = {}
        self.route_locations = {}
        self.stop_code_mapping_file = stop_code_mapping_file
        self.stop_code_mappings = {}

    def read_files(self, files):
        '''Loads in multiple ATCO-CIF files.'''
        for file in files:
            self.input_filename = file
            self.read(file)
            
    # reload all ATCO files, setting load function to given one
    def read_all(self, func):
        # reset file number counter
        self.file_loading_number = 0
        # change the loading function to the one asked for
        self.item_loaded = func
        # do the loading
        self.read_files(self.nptdr_files)
   
    def dump_stops(self):
        self.outfile = csv.writer(open(self.outfilepath, 'w'), 
                                  delimiter="\t", 
                                  quotechar='"', 
                                  quoting=csv.QUOTE_MINIMAL) 
        self.outfile.writerow(['Location Code', 
                               'Name', 
                               'Easting', 
                               'Northing', 
                               'Gazeteer Code', 
                               'Point Type', 
                               'National Gazetteer ID', 
                               'District Name', 
                               'Town Name'])
        self.read_all(self.dump_stops_to_file)
    
    def dump_stops_to_file(self, item):
        # locations only
        if not isinstance(item, mysociety.atcocif.Location):
            return
        assert item.transaction_type == 'N'
        assert item.additional.transaction_type == 'N'
        if not self.stops_dumped.get(item.location) == 1:
            self.outfile.writerow([item.location, 
                              item.full_location,
                              item.additional.grid_reference_easting, 
                              item.additional.grid_reference_northing, 
                              item.gazetteer_code,
                              item.point_type, 
                              item.national_gazetteer_id, 
                              item.additional.district_name, 
                              item.additional.town_name])
        self.stops_dumped[item.location] = 1
        
    def dump_routes(self):
        self.outfile = csv.writer(open(self.outfilepath, 'w'), 
                                  delimiter="\t", 
                                  quotechar='"', 
                                  quoting=csv.QUOTE_MINIMAL) 
        self.outfile.writerow(['Vehicle Code', 
                               'Route Number', 
                               'Operator Code', 
                               'Default Vehicle Code', 
                               'Locations'])
        # Read the file once to get the vehicle type mappings
        self.read_all(self.noop)
        self.read_all(self.dump_routes_to_file)
        
    def noop(self, item):
        return 
        
    def dump_routes_to_file(self, item):
        if not isinstance(item, mysociety.atcocif.JourneyHeader):
            return
        assert item.transaction_type == 'N'
        if item.vehicle_type != '':
            vehicle_code = item.vehicle_code(self)
            default_code = False
        else:
            vehicle_code = self.vehicle_code_from_filename()
            default_code = True
        identifier = item.route_number + vehicle_code + item.operator
        locations = []
        for hop in item.hops:
            location = self.new_stop_code(hop.location)
            locations.append(location)
        if not locations in self.route_locations.setdefault(identifier, []):
            self.route_locations[identifier].append(locations)
            self.outfile.writerow([vehicle_code, 
                                   item.route_number, 
                                   item.operator, 
                                   default_code, 
                                   ','.join(locations)])
     
    def vehicle_code_from_filename(self):
        basename, ext = os.path.splitext(self.input_filename)
        name_parts = basename.split("_")
        name_mappings = { "BUS"  : 'B',
                         "COACH": 'C',
                         "FERRY": 'F',
                         "AIR"  : 'A', 
                         "TRAIN": 'T', 
                         "METRO": 'M' }
        return name_mappings[name_parts[-1]]

    def new_stop_code(self, stop_code):
        if not self.stop_code_mappings:
           mapping_file = open(self.stop_code_mapping_file)
           for line in mapping_file:
               data = line.split("\t")
               self.stop_code_mappings[data[0]] = data[1] 
        return self.stop_code_mappings.get(stop_code, stop_code)
    
def setup_atco(nptdr_files, outfilepath, stop_code_mapping_file=None):
    atco = CSVDumpATCO(nptdr_files, outfilepath, stop_code_mapping_file, True)
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
    

def data_dirs():
    return [name for name in os.listdir(options.datadir) if os.path.isdir(os.path.join(options.datadir, name))]
    
def cif_files(directory):
    # get cif files in this dir and one level down
    full_dir = os.path.join(options.datadir, directory)
    return glob.glob(os.path.join(full_dir, "*.CIF")) + glob.glob(os.path.join(full_dir, "*", "*.CIF"))

def dump_stops():
    for subdir in data_dirs():
        outfilepath = os.path.join(options.outdir, "%s_stops.tsv" % subdir)
        if os.path.exists(outfilepath):
            continue 
        nptdr_files = cif_files(subdir)
        atco = setup_atco(nptdr_files=nptdr_files, 
                          outfilepath=outfilepath)      
        atco.dump_stops()
       
def dump_routes():    
    for subdir in data_dirs():
        outfilepath = os.path.join(options.outdir, "%s.tsv" % subdir)
        if os.path.exists(outfilepath):
            continue
        nptdr_files = cif_files(subdir)
        
        atco = setup_atco(nptdr_files=nptdr_files, 
                          outfilepath=outfilepath,
                          stop_code_mapping_file=options.stop_code_mapping_file)      
        atco.dump_routes()
         
if command == 'stops':
    dump_stops()
if command == 'routes':
    dump_routes()         