function [smooth, params] = filt_rec_smooth(unfilt, fs, f_low, f_high, filter_type, sm_win)
% filt_rec_smooth.m
% 2024.02.12 CDR
% supercedes filter_segment; also see function segment_calls
% 
% Filters, rectifies, and smooths audio data using evsmooth from
% evsonganaly.

if (~exist('sm_win', 'var'))
	sm_win = 2.0;%ms
end

for i=size(unfilt,1):-1:1
    smooth{i} = evsmooth(unfilt(i, :), fs, sm_win, f_low, f_high, filter_type);
end

smooth = cell2mat(smooth');

params.filter_type = filter_type;
params.f_low = f_low;
params.f_high = f_high;
params.sm_win = sm_win;


end

