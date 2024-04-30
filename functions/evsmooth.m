function [smooth]=evsmooth(rawsong, fs, sm_win, f_low, f_high, filter_type)
% [smooth,spec,t,f]=evsmooth(rawsong,Fs,SPTH,nfft,olap,sm_win,F_low,F_High);
% returns the smoothed waveform/envelope
%
% 2024.02.12 CDR, taken from evsonganaly. removed spectrogramming & default values
% 

filtsong=pj_bandpass(rawsong,fs,f_low,f_high,filter_type);

squared_song = filtsong.^2;

%smooth the rectified song
len = round(fs*sm_win/1000);
h   = ones(1,len)/len;
smooth = conv(h, squared_song);
offset = round((length(smooth)-length(filtsong))/2);
smooth=smooth(1+offset:length(filtsong)+offset);

%smooth(500:510)
return;
