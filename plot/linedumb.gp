reset
set xlabel 'iteration#'
set ylabel 'bw' offset character 1,0
set title 'performance test'
set datafile separator ","
set terminal dumb size 138,33 ansi

plot [:] \
'output.csv' using 1:2 with linespoints linewidth 2 title "r", \
'output.csv' using 1:4 with linespoints linewidth 2 title "w" \
