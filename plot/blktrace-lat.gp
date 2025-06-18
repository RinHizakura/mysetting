reset
set term png
set output "output.png"
set xlabel 'Runtime (secs)'
set ylabel 'Latency (us)'

plot [:] \
  'd2c_lat.dat' using 1:(1000000*$2) with linespoints lw 2 title "d2c", \
  'q2c_lat.dat' using 1:(1000000*$2) with linespoints lw 2 title "q2c", \
  'q2d_lat.dat' using 1:(1000000*$2) with linespoints lw 2 title "q2d"
