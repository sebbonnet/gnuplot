#!/usr/bin/env bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
timeseries_datafile=$(mktemp)
from_timestamp=$(date +%s%3N -d "7 day ago")
to_timestamp=$(date +%s%3N)
query="kubernetes.container_name: \\\"ping\\\" && message: \\\"Slow request https://p.sky.com/commerce/verification-app/private/ready\\\""

# Query ES and extract timestamp(epoc seconds not millis), host and request duration
# e.g: 1494316181 23.40.212.43 2009
QUERY=${query} FROM=${from_timestamp} TO=${to_timestamp} ${script_dir}/query-elastic-search.sh \
    | sed -e  's/^"//' -e 's/"$//' \
    | awk -F "[,=]" '{printf "%.0f %s %s\n", $1/1000, $3, $8}' \
    | sed -e 's/ms//g' -e 's/"//g' \
    > ${timeseries_datafile}

TIME_SERIES=${timeseries_datafile} ${script_dir}/plot-host-request-durations.sh
rm -f ${timeseries_datafile}
