#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#define max(a,b)				\
  ({ __typeof__ (a) _a = (a);			\
    __typeof__ (b) _b = (b);			\
    _a > _b ? _a : _b; })

double uniform_rv(int lo, int hi){
  return((double)lo+rand()/(RAND_MAX/((double)hi-(double)lo)+1));
}

int main(int argc, char* argv[]){
  int i;
  int T = 1000000;
  double lambda = 0.0;
  double mu = 0.5;
  int A = 0;
  int S = 0;
  int Q[1000000];
  double Q_avg;
  srand(time(NULL));
  for(lambda=0;lambda<0.500;lambda+=0.001){
    Q_avg = 0;
    for(i=0;i<T;i++){
      A = (uniform_rv(0,1)<lambda);
      S = (uniform_rv(0,1)<mu);
      Q[i+1] = max(Q[i]+A-S,0);
      //printf("%d\t%d\n",i,Q[i]);
      Q_avg += Q[i];
    }
    Q_avg /= (double)T;
    printf("%.2f\t%.2f\n",lambda, Q_avg);
  }
}

