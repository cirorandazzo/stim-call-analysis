%% main.m
% 2024.02.12 CDR
% 
% pipeline for audio data processing

clear;

%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters

verbose = 1;

%--files
p.files.raw_data = '/Users/cirorandazzo/ek-spectral-analysis/dm stim/DMStim_bu69bu75.mat';
mat_file = true;

p.files.save_folder = '/Users/cirorandazzo/ek-spectral-analysis/data/pipeline/testing';
% p.files.save_folder = '/Users/cirorandazzo/ek-spectral-analysis/data/pipeline';
p.files.bird_name = 'bk68wh15';

% p.files.labels = {"current", "frequency", "length"};
p.files.labels = {};

save_prefix = [p.files.save_folder  '/'  p.files.bird_name ];

p.fs = 30000;


%--breathing filter parameters
p.filt_breath.type = 'lowpassfir';
p.filt_breath.FilterOrder = 30;
p.filt_breath.PassbandFrequency = 400;
p.filt_breath.StopbandFrequency = 450;


%--windowing
p.window.radius = 1;  % for each window, time before and after stim (seconds). usually 1s, for total window length of 2s 
p.window.stim_i = 30001;  % stimulation onset frame index

p.breath_time.post_stim_call_window = ([15 150] * p.fs/1000)+p.window.stim_i;  % only check for call trial within this window after stim onset


%--post-stim breathing windows
p.breath_time.insp_dur_max = 100;  % how long after stimulation to check for inspiration (milliseconds). usually 100ms
p.breath_time.exp_delay = 50;  % how long to wait after stimulation before checking for expiration (milliseconds). usually 50ms
p.breath_time.exp_dur_max = 300;  % window after call onset in which to check expiratory amplitude. usually 300ms

%--filtering/smoothing options
p.filt_smooth.f_low = 500;
p.filt_smooth.f_high = 10000;
p.filt_smooth.sm_window = 2.0; % ms
p.filt_smooth.filt_type = 'butterworth';

%--noise thresholding options
p.call_seg.q = 5;  % threshold = p.call_seg.q*MEDIAN

p.call_seg.min_int = 10;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_dur = 15;  % ms; minimum duration of note to be considered (else ignored)

%--breath segmentation
p.breath_seg.dur_thresh = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.01;
p.breath_seg.insp_thresh = -0.03;

% time (ms) before/after stim to consider breaths "pre"/"post" call
p.breath_seg.pre_delay  = 10 / p.fs * 1000;  % 10 frames
p.breath_seg.post_delay = 150;  % 150 ms

%--call vicinity


%% STEP 1: load intan data

if verbose 
    disp('Loading raw data...');
    tic
end

if mat_file
    load(p.files.raw_data, 'dataMat');

    % rename for consistency
    unproc_data = dataMat;
    clear dataMat;

    unproc_data = renameStructField(unproc_data, 'audio', 'sound');
    unproc_data.fs = p.fs;

    if verbose 
        toc
        disp('Loaded!');
    end

else  % directory of intan files
    unproc_data = s1_load_raw(p.files.raw_data, [save_prefix '_unproc_data.mat']);

    if verbose 
        toc
        disp(['Loaded! Saved to: ' save_prefix '_unproc_data.mat' newline]);
    end

end

%% create breathing filter

deq_br = designfilt(...
    p.filt_breath.type,...
    'FilterOrder', p.filt_breath.FilterOrder,...
    'PassbandFrequency', p.filt_breath.PassbandFrequency,...
    'StopbandFrequency', p.filt_breath.StopbandFrequency,...
    'SampleRate', p.fs);

%% STEP 2: restructure data, filter breathing

if verbose 
    disp('Restructuring data...');
    tic
end

proc_data = s2_restructure( ...
    unproc_data, ...
    [save_prefix '_proc_data.mat'], ...
    deq_br, p.files.labels, p.window.radius, p.breath_time.insp_dur_max, p.breath_time.exp_delay, p.breath_time.exp_dur_max);

if verbose 
    toc
    disp(['Restructured! Saved to: ' save_prefix '_proc_data.mat' newline]);
end

%% STEP 3: segment calls.
% filter/smooth happens here too

if verbose 
    disp('Segmenting calls...');
end

call_seg_data = s3_segment_calls( ...
    proc_data, ...
    [save_prefix '_call_seg_data.mat'],...
    p.fs, ...
    p.filt_smooth.f_low, ...
    p.filt_smooth.f_high, ...
    p.filt_smooth.sm_window, ...
    p.filt_smooth.filt_type, ...
    p.call_seg.min_int, ...
    p.call_seg.min_dur, ...
    p.call_seg.q, ...
    p.window.stim_i, ...
    p.breath_time.post_stim_call_window);

if verbose 
    disp(['Segmented calls! Saved to: ' save_prefix '_call_seg_data.mat' newline]);
end

% see b_segment_calls.m for code to plot spectrograms for subset of trials
% (eg, where no call is found)


%% STEP 4: segment breaths

if verbose 
    disp('Segmenting breaths...');
end

call_breath_seg_data = s4_segment_breaths( ...
    call_seg_data, ...
    [save_prefix '_breath_seg_data.mat'], ...
    p.fs, ...
    p.window.stim_i, ...
    p.breath_seg.dur_thresh, ...
    p.breath_seg.exp_thresh, ...
    p.breath_seg.insp_thresh, ...
    p.breath_seg.pre_delay, ...
    p.breath_seg.post_delay ...
    );

if verbose 
    disp(['Segmented breaths! Saved to: ' save_prefix '_breath_seg_data.mat' newline]);
end


%% STEP 5: call vicinity analysis
% TODO: what do breaths look like directly before/after call?

%% SAVE PARAMETERS

save([save_prefix '_parameters.mat'], 'p');

if verbose 
    disp(['Parameters saved to: ' save_prefix '_parameters.mat' newline]);
end
