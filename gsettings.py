#!/usr/bin/python
"""docstring    """
# Drew Holt <drew@invadelabs.com>
# python gsettings.py <schema> <key> <value>
# e.x.: python gsettings.py org.gnome.rhythmbox.encoding-settings media-type "'audio/x-vorbis'"

import sys

GSETTINGS = open("gsettings_output.txt", "r")

RAW = GSETTINGS.read().splitlines()

# create list of "<schema>, '<key> <value>'"
FIRST_SPLIT = list(s.split(' ', 1) for s in RAW)

PROCESSED = {}

for key, value in sorted(FIRST_SPLIT):
    second_split = value.split(' ', 1)  # create list of '<key>,<value>'
    third_split = {second_split[0]: second_split[1]} # create dictionary "<key>: '<value>'"
    # dictionary handle multiple schema in "<schema>: ['key': '<value>']"
    PROCESSED.setdefault(key, []).append(third_split)

try:
    A = sys.argv[1]
    B = sys.argv[2]
    C = sys.argv[3]
    if PROCESSED[A][0][B] == C:
        print "set"
    else:
        print "not set"
except (KeyError, IndexError):
    print "error"
    sys.exit(1)

GSETTINGS.close()
