% b_segment_calls.m
% 2023.12.13 CDR
% 
% get spectral features of processed data

clear
close all
clc

%% load processed data

file_path = '/Users/cirorandazzo/ek-spectral-analysis/proc_data-pk70pu50.mat';
save_file = '/Users/cirorandazzo/ek-spectral-analysis/call_seg_data-pk70pu50.mat';

load(file_path);

%% processing & plotting parameters

fs = 30000;

%--windowing/spectrogram options
n = 1024;
overlap = 1020;
sigma = 3;

f_low = 500;
f_high = 10000;

spec_threshold = .04; % determined manually; see spectrogram_thresholding.m


%--noise thresholding options
show_onsets = 1;

q = 5;  % threshold = q*MEDIAN

% NOTE: below values are in ms
min_int = 10;  % minimum time between 2 notes to be considered separate notes (else merged)
min_dur = 15;  % minimum duration of note to be considered (else ignored)

stim_i = 30001;  % stimulation onset frame index

post_stim_to_check = ([15 150] * fs/1000)+stim_i;  % only check for call trial within this window after stim onset

%% get onsets/offsets for every trial

tic;

for c=length(proc_data):-1:1  % for each condition
    a = proc_data(c).audio;
    
    [audio_filt, ...
        proc_data(c).noise_thresholds, ...
        onsets, ...
        offsets ...
        ] = filter_segment(a, fs, f_low, f_high, min_int, min_dur, q, stim_i);

    % only take calls within desired window
    
    % check onsets/onsets individually
    i_on = cellfun(@(x) x >=post_stim_to_check(1) & x<=post_stim_to_check(2), onsets, 'UniformOutput',false);
    i_off = cellfun(@(x) x >=post_stim_to_check(1) & x<=post_stim_to_check(2), offsets, 'UniformOutput',false);

    % ensure both onset/offset are within that window
    i_good = arrayfun(@(i) {i_on{i} & i_off{i}}, 1:size(i_on,1));

    % delete remainder
    onsets_old = onsets;
    offsets_old = offsets;
    onsets = arrayfun(@(i)  onsets{i}(i_good{i}), 1:size(i_on,1), 'UniformOutput',false)';
    offsets = arrayfun(@(i) offsets{i}(i_good{i}), 1:size(i_on,1), 'UniformOutput',false)';

    proc_data(c).audio_filt = audio_filt;
    proc_data(c).onsets = onsets;
    proc_data(c).offsets = offsets;

    % Helps determine if audio segmentation was successful
    proc_data(c).no_calls = find(cellfun(@isempty, onsets));  % NO CALLS FOUND
    proc_data(c).one_call = find(cellfun(@(x) length(x)==1, onsets)); % EXACTLY 1 CALL
    proc_data(c).multi_calls = find(cellfun(@(x) length(x)>1, onsets));  % >1 CALL

    % For trials with EXACTLY ONE call, cut & save 
    if ~isempty(proc_data(c).one_call)
        proc_data(c).audio_filt_call = arrayfun(@(tr) audio_filt(tr, onsets{tr}:offsets{tr}) , proc_data(c).one_call, 'UniformOutput',false);
    end

    % Save processing parameters
    proc_data(c).q = q;
    proc_data(c).min_int = min_int;
    proc_data(c).min_dur = min_dur;
end

% rename struct
call_seg_data = proc_data;
clear proc_data


toc;
%% SAVE

save(save_file, 'call_seg_data')

%% PLOT SUBSET OF TRIAL SPECTROGRAMS
% eg, only trials with no calls detected
% close all;

to_plot = 1;
cols = 5;
max_to_plot = 10;

condition = 1;  % index in proc_data

if to_plot
    tic;
    %--MANUALLY SELECT SUBSET
    % select_trials = call_seg_data(condition).no_calls(1:10);
    % select_trials = 1:10;
    
    %--AUTOMATICALLY SELECT SUBSET (eg, trials with no calls)
    select_trials = call_seg_data(condition).one_call;
    % select_trials = call_seg_data(condition).multi_calls;
    if length(select_trials) > max_to_plot  % take subset of trials if there are too many
        % select_trials = select_trials(1:max_to_plot);  % from start
        select_trials = select_trials(randi(length(select_trials), max_to_plot));  % random subset 
    end


    a = call_seg_data(condition).audio(select_trials, :);
    onsets = call_seg_data(condition).onsets;
    offsets = call_seg_data(condition).offsets;

    f = figure();
    % f.WindowState = 'maximized';
    % set(f,'Position',[-1079 -295 1080 869]);
    
    rows = ceil(length(select_trials)/cols);
    
    for i=1:length(select_trials)
        orig_i = select_trials(i);
    
        filtsong=pj_bandpass(a(i,:), fs, f_low, f_high, 'butterworth');
        noise_threshold = q * median(abs(filtsong));
    
        subplot(rows,cols,i);
    
        ms_off = offsets{orig_i} * 1000 / fs;
        ms_on = onsets{orig_i} * 1000 / fs;
    
        plot_spectr_callLines(filtsong, ms_on, ms_off, fs, spec_threshold, n , overlap, f_low, f_high);
        xlim([stim_i-10000 stim_i+10000]*1000 / fs);

        title(select_trials(i));
        hold off;
    end
    toc;
end