%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters
% 
% NOTE: saved as bird_080720 since eval('080720') --> int

verbose = 0;

%--files
p.files.raw_data = '/Users/cirorandazzo/ek-spectral-analysis/dm stim/DMStim_080720.mat';
mat_file = true;

p.files.bird_name = '080720';
p.files.save_folder = ['/Users/cirorandazzo/ek-spectral-analysis/data/pipeline/dm_stim'];

p.files.labels = {};

save_prefix = [p.files.save_folder  '/'  p.files.bird_name ];

p.fs = 30000;


%--save files
% empty array to skip saving
p.files.save.unproc_save_file   = [];
p.files.save.proc_save_file     = [];
p.files.save.call_seg_save_file = [];
p.files.save.call_breath_seg_save_file = [];
p.files.save.vicinity_save_file = [save_prefix '_data.mat'];
p.files.save.parameter_save_file = [save_prefix '_parameters.mat'];

clear save_prefix;

%--breathing filter parameters
p.filt_breath.type = 'lowpassfir';
p.filt_breath.FilterOrder = 30;
p.filt_breath.PassbandFrequency = 400;
p.filt_breath.StopbandFrequency = 450;


%--windowing
p.window.radius = 1.5;  % for each window, time before and after stim (seconds). usually 1s, for total window length of 2s 
p.window.stim_i = p.window.radius * p.fs + 1;  % stimulation onset frame index

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
p.breath_seg.exp_thresh = 0.001;
p.breath_seg.insp_thresh = -0.003;

% time (ms) before/after stim to consider breaths "pre"/"post" call
p.breath_seg.pre_delay  = 10 / p.fs * 1000;  % 10 frames
p.breath_seg.post_delay = 150;  % 150 ms

%--call vicinity
p.call_vicinity.post_window = 50;  % time (ms) after call onset to

