#!/usr/bin/python

# This script finds the first problem report from each unique email
# address, and classifies it according to whether it was confirmed or
# unconfirmed.  It outputs a CSV file that groups these results by
# domain, tell you how many confirmed emails, bounced emails and
# neither-confirmed-nor-bounced emails there were per domain.

import psycopg2
import datetime
from collections import namedtuple, defaultdict
import operator
import re
import csv

connection = psycopg2.connect("dbname=fmt user=fmt")
c = connection.cursor()

start_date = datetime.date(2012, 4, 10)
end_date = datetime.date(2012, 7, 1)

c.execute('''SELECT email, status_code
               FROM users, problems
               WHERE users.id = problems.reporter_id
                 AND problems.created_at >= %s
                 AND problems.created_at < %s
               ORDER BY problems.created_at''',
          (start_date, end_date))

reports_domains = defaultdict(int)
unconfirmed_domains = defaultdict(int)
bounced_domains = defaultdict(int)

already_seen_addresses = set()

group_domains = {'hotmail.com': 'hotmail',
                 'hotmail.co.uk': 'hotmail',
                 'live.co.uk': 'hotmail',
                 'live.com': 'hotmail',
                 'live.com.au': 'hotmail',
                 'googlemail.com': 'gmail',
                 'gmail.com': 'gmail',
                 'yahoo.com': 'yahoo',
                 'yahoo.co.uk': 'yahoo',
                 'btinternet.com': 'yahoo'}

def get_domain(email_address):
    domain = re.sub(r'^.*@', '', email_address)
    return group_domains.get(domain, domain)

# This file was was generated with find-bounces.py > bounced-addresses

bounce_filename = ('/home/fixmytransport/' +
                   'bounced-addresses-%s-to-%s') % (start_date, end_date)

with open(bounce_filename) as fp:
    for line in fp:
        email_address = line.strip().lower()
        if email_address in already_seen_addresses:
            continue
        else:
            already_seen_addresses.add(email_address)
        domain = get_domain(email_address)
        bounced_domains[domain] += 1

already_seen_addresses = set()

for row in c:
    email_address = row[0].lower()
    if email_address in already_seen_addresses:
        continue
    else:
        already_seen_addresses.add(email_address)
    status_code = row[1]
    domain = get_domain(email_address)
    reports_domains[domain] += 1
    if status_code == 0:
        unconfirmed_domains[domain] += 1

all_domains = set(reports_domains.keys() +
                  unconfirmed_domains.keys() +
                  bounced_domains.keys())

with open('domain-distribution.csv', 'wb') as fp:
    writer = csv.writer(fp)
    writer.writerow(['Domain', 'Fine', 'UnconfirmedNotBounced', 'Bounced'])
    for domain in all_domains:
        problems = reports_domains.get(domain, 0)
        unconfirmed = unconfirmed_domains.get(domain, 0)
        bounced = bounced_domains.get(domain, 0)
        fine = problems - unconfirmed
        unconfirmed_not_bounced = unconfirmed - bounced
        writer.writerow([domain,
                         fine,
                         unconfirmed_not_bounced,
                         bounced])
