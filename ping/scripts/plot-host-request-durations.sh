#!/bin/bash -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
gnu_datafile="gnuplot.dat"
plot_datafile=$(mktemp)

if [ -z "$TIME_SERIES" ]; then
    echo "Must provide TIME_SERIES variable"
    exit 1
fi

if [ ! -f "$TIME_SERIES" ]; then
    echo "No time series file found at: ${TIME_SERIES}"
    exit 1
fi

# Convert timeseries to a gnuplot friendly format
# From:
#     1494316181 23.40.212.43 2009
#     1494313823 104.81.4.64 1002
# To:
#    timestamp,23.65.214.129,104.68.183.11
#    1494316181,2009,
#    1494313823,,1002
echo "Converting $(wc -l ${TIME_SERIES}) timeseries from ${TIME_SERIES} to a gnuplot friendly format..."
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
}' ${TIME_SERIES} ${TIME_SERIES} > ${gnu_datafile}

# Plot the timeseries
echo "Plotting the data file ${gnu_datafile} with gnuplot..."
gnuplot -e "data_file='${gnu_datafile}'" ${script_dir}/hosts-request-duration.gnu > hosts-request-duration.png
echo "Plot graph: hosts-request-duration.png"
rm -f ${gnu_datafile}
