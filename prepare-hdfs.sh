#!/bin/bash

source pig.sh

for file in lib/*.jar; do
	hdfs $file
done

for file in `find pig -name '*.pig'`; do
	hdfs $file
done

hdfs data/GeoIP.dat
hdfs data/GeoIPASNum.dat
hdfs data/GeoLiteCity.dat

