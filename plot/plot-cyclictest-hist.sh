#!/usr/bin/env bash

# Reference: https://www.osadl.org/uploads/media/mklatencyplot.bash

set -e

INPUT=${1:-(none)}
OUTPUT_IMG=$2

if [ ! -f $INPUT ]
then
    echo File $INPUT is not exist
    exit 1
fi

if [ -z $OUTPUT_IMG ]
then
    DUMB_PLOT=1
    cols=$(tput cols)
    rows=$(tput lines);
    OUTPUT="set terminal dumb size $cols,$rows ansi\n"
else
    DUMB_PLOT=0
    OUTPUT="set output \"$OUTPUT_IMG\"\n"
fi

# Get maximum latency
max=`grep "Max Latencies" output | tr " " "\n" | sort -n | tail -1 | sed s/^0*//`

# Grep data lines, remove empty lines and create a common field separator
grep -v -e "^#" -e "^$" output | tr " " "\t" >/tmp/histogram

# Set the number of cores, for example
cores=`nproc --all`

# Create two-column data sets with latency classes and frequency values for each core, for example
for i in `seq 1 $cores`
do
  column=`expr $i + 1`
  cut -f1,$column /tmp/histogram >/tmp/histogram$i
done

# Create plot command header
echo -n -e "set title \"Latency plot\"\n\
set terminal png\n\
set xlabel \"Latency (us), max $max us\"\n\
set logscale y\n\
set xrange [0:400]\n\
set yrange [0.8:*]\n\
set ylabel \"Number of latency samples\"\n" > /tmp/plotcmd

echo -n -e $OUTPUT >> /tmp/plotcmd
echo -n -e "plot " >> /tmp/plotcmd

# Append plot command data references
for i in `seq 1 $cores`
do
  if test $i != 1
  then
    echo -n ", " >>/tmp/plotcmd
  fi
  cpuno=$((i-1))
  if test $cpuno -lt 10
  then
    title=" CPU$cpuno"
   else
    title="CPU$cpuno"
  fi
  echo -n "\"/tmp/histogram$i\" using 1:2 title \"$title\" with histeps" >>/tmp/plotcmd
done

# Execute plot command
if [ $DUMB_PLOT = 0 ]
then
        gnuplot -persist < /tmp/plotcmd
        echo Result is output to $OUTPUT_IMG
else
        gnuplot /tmp/plotcmd
fi

