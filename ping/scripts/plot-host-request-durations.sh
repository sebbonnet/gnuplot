#!/bin/bash -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
timeseries_datafile=${TIME_SERIES:-$(mktemp)}
gnu_datafile="gnuplot.dat"
plot_datafile=$(mktemp)
from_timestamp=$(date +%s%3N -d "7 day ago")
to_timestamp=$(date +%s%3N)
query="kubernetes.container_name: \\\"ping\\\" && message: \\\"Slow request https://p.sky.com/commerce/verification-app/private/ready\\\""

if [ "$TIME_SERIES" = "" ]; then
    # Query ES and extract timestamp(epoc seconds not millis), host and request duration
    # e.g: 1494316181 23.40.212.43 2009
    QUERY=${query} FROM=${from_timestamp} TO=${to_timestamp} ${script_dir}/query-elastic-search.sh \
        | sed -e  's/^"//' -e 's/"$//' \
        | awk -F "[,=]" '{printf "%.0f %s %s\n", $1/1000, $3, $8}' \
        | sed -e 's/ms//g' -e 's/"//g' \
        > ${timeseries_datafile}
fi

# Convert timeseries to a gnuplot friendly format
# From:
#     1494316181 23.40.212.43 2009
#     1494313823 104.81.4.64 1002
# To:
#    timestamp,23.65.214.129,104.68.183.11
#    1494316181,2009,
#    1494313823,,1002
echo "Converting the timeseries ${timeseries_datafile} to a gnuplot friendly format..."
rm -f ${gnu_datafile}
awk 'NR==FNR{
    # fill in hosts on 1st file pass
    hosts[$2]

    # skip next section on 1st file pass
    next
}
{
  # CSV header
  if (!header) {
    header = "timestamp"
    for (host in hosts) {
	    header = header "," host
    }
    print header
  }

  # CSV data
  row = ""
  for (host in hosts) {
    row = row ","
	if ($2 == host) {
	  row = row "" $3
	}
  }
  printf "%s%s\n", $1, row
}' ${timeseries_datafile} ${timeseries_datafile} > ${gnu_datafile}

# Plot the timeseries
echo "Plotting the data file ${gnu_datafile} with gnuplot..."
gnuplot -e "data_file='${gnu_datafile}'" ${script_dir}/hosts-request-duration.gnu > hosts-request-duration.png
echo "Plot graph: hosts-request-duration.png"
