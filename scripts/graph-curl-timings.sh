#!/bin/bash -e

# Convert custom curl timings to a timeseries friendly format
# From:
#     date=08/25/17T16:29:55.059 timestamp=1503678595113 requestid=Td0sKOk1UxPtrAwNdDvXBJKX7GpMUTVbJezE host=72.247.83.240 status=200 totaltime=2.357
#     date=08/25/17T16:30:03.568 timestamp=1503678603569 requestid=WCLkIMtLOXqwZQDMgbyMgvWT97uXB2uYoFyE host=72.247.83.240 status=200 totaltime=0.904
# To:
#     1503678595 72.247.83.240 2357
#     1503678604 72.247.83.240 904

if [ -z "$TIMINGS" ]; then
    echo "Must provide TIMINGS variable"
    exit 1
fi

if [ ! -f "$TIMINGS" ]; then
    echo "No file found at: ${TIMINGS}"
    exit 1
fi

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
timeseries_datafile=$(mktemp)
cat ${TIMINGS} | awk -F "[ =]" '{printf "%.0f %s %s\n", $4/1000, $8, $12*1000 }' > ${timeseries_datafile}

TIME_SERIES=${timeseries_datafile} ${script_dir}/plot-host-request-durations.sh
rm -f ${timeseries_datafile}
