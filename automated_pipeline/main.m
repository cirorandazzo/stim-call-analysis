%% main.m
% 2024.02.12 CDR
% 
% pipeline for audio data processing

clear;

%%
verbose = 1;

raw_data_dir = '/Users/cirorandazzo/ek-spectral-analysis/data/PAm stim/052222_bk68wh15';
save_folder = '/Users/cirorandazzo/ek-spectral-analysis/data/pipeline';
bird_name = 'bk68wh15';

save_prefix = [save_folder  '/'  bird_name ];

fs = 30000;

%% STEP 1: load intan data

if verbose 
    disp('Loading raw data...');
    tic
end

unproc_data = s1_load_raw(raw_data_dir, [save_prefix '_unproc_data.mat']);


if verbose 
    toc
    disp(['Loaded! Saved to: ' save_prefix '_unproc_data.mat' newline]);
end

%% create breathing filter

deq_br = designfilt(...
    'lowpassfir',...
    'FilterOrder', 30,...
    'PassbandFrequency', 400,...
    'StopbandFrequency', 450,...
    'SampleRate', fs);

%% processing settings

%--windowing
radius = 1; % for each window, time before and after stim (seconds). usually 1s, for total window length of 2s 


%--post-stim breathing windows
insp_dur_max = 100;
exp_delay = 50;
exp_dur_max = 300;

%   insp_dur_max: how long after stimulation to check for inspiration (milliseconds). usually 100ms
%   exp_delay: how long to wait after stimulation before checking for expiration (milliseconds). usually 50ms
%   exp_dur_max: window after call onset in which to check expiratory amplitude. usually 300ms 


%--spectrogram options
f_low = 500;
f_high = 10000;
filt_type = 'butterworth';

%--noise thresholding options
show_onsets = 1;

q = 5;  % threshold = q*MEDIAN

% NOTE: below values are in ms
min_int = 10;  % minimum time between 2 notes to be considered separate notes (else merged)
min_dur = 15;  % minimum duration of note to be considered (else ignored)

stim_i = 30001;  % stimulation onset frame index

post_stim_call_window = ([15 150] * fs/1000)+stim_i;  % only check for call trial within this window after stim onset


%% STEP 2: restructure data, filter breathing

labels = {"current", "frequency", "length"};

if verbose 
    disp('Restructuring data...');
    tic
end

proc_data = s2_restructure( ...
    unproc_data, ...
    [save_prefix '_proc_data.mat'], ...
    deq_br, labels, radius, insp_dur_max, exp_delay, exp_dur_max);

if verbose 
    toc
    disp(['Restructured! Saved to: ' save_prefix '_proc_data.mat' newline]);
end

%% STEP 3: segment calls

if verbose 
    disp('Segmenting calls...');
end

call_seg_data = s3_segment_calls( ...
    proc_data, ...
    [save_prefix '_call_seg_data.mat'],...
    fs, f_low, f_high, filt_type, ...
    min_int, min_dur, q, stim_i, post_stim_call_window);

if verbose 
    disp(['Segmented! Saved to: ' save_prefix '_call_seg_data.mat' newline]);
end

% see b_segment_calls.m for code to plot spectrograms for subset of trials
% (eg, where no call is found)


%% TODO: breath segmentation

%% breath segmentation parameters

%% STEP 4: segment breaths
