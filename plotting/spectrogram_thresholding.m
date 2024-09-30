%% spectrogram_thresholding.m
% 2023.01.04 CDR
% 
% Testing out spectrogram thresholds on a subset of trials

%% load processed data

file_path = "/Users/cirorandazzo/ek-spectral-analysis/proc_data.mat";

load(file_path);

a = proc_data(1).audio(2, :);
filtsong=pj_bandpass(a, fs, f_low, f_high, 'butterworth');

%% Find Spectrogram Threshold

thresholds = [.001 .01 .04 .05 .06 .07];
i=1;

f = figure();
set(f,'Position',[2561 1 1792 1016]);

for threshold = thresholds
    subplot(2,3,i);
    S = ek_spectrogram(filtsong, fs, threshold, n, overlap, f_low, f_high);
    title(threshold);
    i=i+1;
end