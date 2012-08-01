#!/usr/bin/env python

# Finds all failed addresses from bounces in my fixmytransport mail
# folder between two dates - note that this technically finds all
# bounces, not just those from problem reports, also those from
# comments, etc. or any unrelated to FixMyTransport.  I've made sure
# that there aren't any of the latter classes in that folder, though.

import StringIO
import datetime
import dateutil.parser
import mailbox
import os
import pytz
import re
import sys

mail_directory = "/home/mark/Mail/fixmytransport"

since = datetime.datetime(2012, 7, 1, 0, 0, 0, 0, pytz.UTC)
until = datetime.datetime(2012, 7, 15, 0, 0, 0, 0, pytz.UTC)

bounced = set()

def get_errors(mail):
    skip_next = False
    save_lines = False
    full_error_lines = []
    for line in mail.fp:
        if re.search(r'The following address\(es\) failed:', line):
            skip_next = True
            continue
        if skip_next:
            save_lines = True
            skip_next = False
            continue
        if save_lines:
            stripped_line = line.strip()
            if not stripped_line:
                break
            full_error_lines.append(stripped_line)
    return full_error_lines

for e in os.listdir(mail_directory):
    if not re.search(r'^\d+$', e):
        continue
    filename = os.path.join(mail_directory, e)
    with open(filename, 'rb') as fp:
        # A hack to parse Gnus's nnml format mail folders:
        raw_email = re.sub(r'^X-From-Line: ', 'From ', fp.read())
        for mail in mailbox.PortableUnixMailbox(StringIO.StringIO(raw_email)):
            dt = dateutil.parser.parse(mail['date'])
            if dt < since:
                continue
            if dt > until:
                continue
            if 'subject' not in mail:
                continue
            subject = mail['subject']
            if not re.search(r'^Mail delivery failed', subject):
                continue
            failed_recipient = mail.getheader('X-Failed-Recipients').strip()
            bounced.add(failed_recipient)
            print failed_recipient
            print >> sys.stderr, "\n".join("    " + l for l in get_errors(mail))
