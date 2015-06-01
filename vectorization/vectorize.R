# Example taken from:
#
# http://stackoverflow.com/questions/16902902/why-is-vectorization-faster

n = 10^7
# populate with random nos
v=runif(n)
system.time({vv<-v*v; m<-mean(vv)}); m
system.time({for(i in 1:length(v)) { vv[i]<-v[i]*v[i] }; m<-mean(vv)}); m