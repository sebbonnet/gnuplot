# Plot timeseries on a graph, using the data_file header as title for the axis
#
# Expected timeseries format:
# timestamp,23.65.214.129,104.68.183.11
# 1494316181,2009,
# 1494313823,,1002

if (!exists("graph_title")) graph_title='Hosts request duration'
if (!exists("data_file")) data_file='gnuplot.dat'
set datafile separator ","
set term png size 1024,800 font 'Verdana,8'
set pointsize 1.0
set key outside
set xdata time
set timefmt "%s"
set format x '%d.%m.%Y %H:%M:%S'
set title graph_title
set ylabel "Request duration (ms)"
set yrange [0:10000]
set xtics out rotate by -80

# find number of columns to plot
set macro
num_cols = `cat @data_file | awk -F ',' 'NR==1{print NF}'`

# plot all columns using different point types for each column
plot for [i=2:num_cols] data_file using 1:i title columnheader with points pointtype 4+i
