# gnuplot

Graph requests timings using a command line tools: [gnuplot](http://www.gnuplot.info)

![Example Graph](host-request-duration-example.png?raw=true "Example Graph")

## Pre-requisite 

Install gnuplot - e.g. on fedora `sudo dnf install gnuplot`

## Usage

```
TIMINGS=<timings-file> scripts/graph-curl-timings.sh

Optionally use `GRAPH_NAME` to specify a custom graph title
```

The script is very rudimentary and expects a specific format for the timings file:
- timestamp as epoc millis as the 2nd field value
- host ip address as the 4th field value 
- request time in seconds as the 6th field value 

```
date=08/25/17T16:29:55.059 timestamp=1503678595113 requestid=Td0sKOk1UxPtrAwNdDvXBJKX7GpMUTVbJezE host=72.247.83.240 status=200 totaltime=2.357
date=08/25/17T16:30:03.568 timestamp=1503678603569 requestid=WCLkIMtLOXqwZQDMgbyMgvWT97uXB2uYoFyE host=72.247.83.240 status=200 totaltime=0.904
```

Here is an example on how the timings file could be produced

```
#/bin/bash -e                          

while true                             
do                                     
    uuid=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 36 | head -n 1)    
    current_date=$(date +"%DT%T.%3N")  
    current_timestamp_millis=$(date +%s%3N)                                   
    host_ip_address=$(getent hosts www.google.co.uk | awk '{ print $1 }')      
    curl_output=$(curl -w "status=%{http_code} totaltime=%{time_total}" -o /dev/null -s http://www.google.co.uk?${uuid})
    echo "date=${current_date} timestamp=${current_timestamp_millis} requestid=${uuid} host=${host_ip_address} ${curl_output}"                               
    sleep 5                            
done                            
```
