% auocorr.m,2024-02-04
 BarkerCodeword2 = [1,-1,1,1,-1,1,1,1,-1,-1,-1];
 BarkerCodeword3 = [-1,1,-1,-1,1,-1,-1,-1,1,1,1];
 [BarkerAutoCorre,lags]=xcorr(BarkerCodeword2,BarkerCodeword2);
 [BarkerAutoCorre2,lags2]=xcorr(BarkerCodeword2,BarkerCodeword3);
 figure;
 plot(lags, BarkerAutoCorre);
 figure
 plot(lags2, BarkerAutoCorre2);