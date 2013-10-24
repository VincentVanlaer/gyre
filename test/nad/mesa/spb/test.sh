#!/bin/bash
#
# File     : gyre.sh
# Purpose  : GYRE testing script

. test_support

# Settings

EXEC=./gyre_nad

IN_FILE=gyre_nad.in
OUT_FILE=gyre_nad.txt

LABEL="MESA model for slowly pulsating B-type star"

RELERR=1E-15
FIELDS=1-5

# Do the tests

run_gyre $EXEC $IN_FILE "$LABEL"
if [ $? -ne 0 ]; then
    exit 1;
fi

check_output $OUT_FILE $RELERR $FIELDS
if [ $? -ne 0 ]; then
    exit 1;
fi

# Clean up output files

rm -f *.txt

# Finish

echo " ...succeeded"
