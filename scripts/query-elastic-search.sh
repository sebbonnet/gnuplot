#!/bin/bash -e

function usage() {
    echo 'Query elastic-search for the given search query.'
    echo 'Returns the search results with matching messages preceded by their timestamp: <timestamp>, <message>'
    echo ''
    echo 'Use default timestamps to search within last 4 hours:'
    echo '  QUERY="kubernetes.container_name: \\\"ping\\\" && message: \\\"Slow request \\\"" ./query-elastic-search.sh'
    echo ''
    echo 'Use custom timestamps:'
    echo '  FROM and TO must be in epoc milliseconds'
    echo '  FROM=`date +%s%3N -d "4 hour ago"` TO=`date +%s%3N` QUERY="kubernetes.container_name: \\\"ping\\\" && message: \\\"Slow request \\\"" ./query-elastic-search.sh'
    echo ''
}

if [ -z "$QUERY" ]; then
    echo "Must provide QUERY variable"
    usage
    exit 1
fi

from_timestamp=${FROM:-$(date +%s%3N -d "4 hour ago")}
to_timestamp=${TO:-$(date +%s%3N)}
search_output=$(mktemp)
es_search_url="https://es.dev.cosmic.sky/tools-*/_msearch?timeout=0"
max_result=10000

echo "Fetching query results from ES for ${QUERY} between ${from_timestamp} and ${to_timestamp}"

cat <<EOF | curl -s -o ${search_output} -s --data-binary @- -H "Content-Type: application/json; charset=UTF-8" ${es_search_url}
{ "ignore_unavailable": true }
{ "size": ${max_result}, "sort": [ { "@timestamp": { "order": "desc", "unmapped_type": "boolean"} }], "query": { "filtered": { "query": { "query_string": { "analyze_wildcard": true, "query": "${QUERY}"} }, "filter": { "bool": { "must": [ { "range": { "@timestamp": { "gte": ${from_timestamp}, "lte": ${to_timestamp}, "format": "epoch_millis"} }} ], "must_not": [] }} }} }
EOF

cat ${search_output} | jq '.[][].hits.hits[]._source.log' \
    | sed -e 's/\\n//g' -e 's/\\"/"/g' -e  's/^"//' -e 's/"$//' \
    | jq '. | [.timestamp, .message] | join(", ")'
