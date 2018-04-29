#!/usr/bin/python
# Drew Holt <drew@invadelabs.com>
# python gsettings.py <schema> <key> <value>
# e.x.: python gsettings.py org.gnome.rhythmbox.encoding-settings media-type "'audio/x-vorbis'"

import sys

file = open("gsettings_output.txt", "r")

raw = file.read().splitlines()

first_split = list(s.split(' ', 1) for s in raw) # create list of "<schema>, '<key> <value>'"

processed = {}

for key, value in sorted(first_split):
  second_split = value.split(' ', 1) # create list of '<key>,<value>'
  third_split = {second_split[0]:second_split[1]} # create dictionary "<key>: '<value>'"
  # dictionary handle multiple schema in "<schema>: ['key': '<value>']"
  processed.setdefault(key, []).append(third_split) 

try:
  a = sys.argv[1]
  b = sys.argv[2]
  c = sys.argv[3]
  if processed[a][0][b] == c:
    print "set"
  else:
    print "not set"
except:
  print "error"
  sys.exit(1)

file.close()
