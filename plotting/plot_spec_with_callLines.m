% plot_spec_with_callLines.m
% 2023.01.08
% 
% Show spectrogram labeled with segmented calls for selected trial(s).

% LOAD 1d DATA STRUCT.

trs=[71];

% % for spontaneous data (rec with evtaf)
% fs = 32000;
% stim_i = 32001;

% % for stim data
fs = 30000;
stim_i = 45001;  % stimulation onset frame index

%--windowing/spectrogram options
n = 1024;
overlap = 1020;

f_low = 500;
f_high = 15000;

spec_threshold = 0.01; % determined manually; see spectrogram_thresholding.m


%%
close all
for j=1:length(trs)
    figure;

    tr = trs(j);

    a = data.audio(tr,:);
    onsets = data.call_seg.onsets{tr} * 1000/fs;
    offsets = data.call_seg.offsets{tr} * 1000/fs;
    
    plotSpectrCallLines(a, onsets, offsets, fs, spec_threshold, n , overlap, f_low, f_high);
    title("tr " + string(tr));
end