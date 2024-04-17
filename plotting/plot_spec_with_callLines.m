% plot_spec_with_callLines.m
% 2023.01.08
% 
% Show 1 trial of spectrogram overlaid with calls. Requires struct output
% from b_segment_calls.m

trs=[8];

fs = 30000;

%--windowing/spectrogram options
n = 1024;
overlap = 1020;

f_low = 500;
f_high = 10000;

spec_threshold = 0; % determined manually; see spectrogram_thresholding.m

stim_i = 45001;  % stimulation onset frame index

%%
% close all
figure
for j=1:length(trs)
    figure;

    tr = trs(j);
    
    % a = audio_filt(tr, :);
    % onset = onsets{tr} * 1000/fs;
    % offset = offsets{tr} * 1000/fs;

    a = data.audio_filt(tr,:);
    onset = data.call_seg.onsets{tr} * 1000/fs;
    offset = data.call_seg.offsets{tr} * 1000/fs;
    
    plot_spectr_callLines(a, onset, offset, fs, spec_threshold, n , overlap, f_low, f_high)
    title("tr " + string(tr));
end