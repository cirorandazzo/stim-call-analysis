function p = default_params(p)
% includes default parameters in parameter struct p.
% WARNING: will overwrite whatever's passed in, so make sure to make edits after calling default_params in a script.

% p.files.delete_fields = {'current', 'length', 'frequency', 'amplitude', 'breathing', 'breathing_filt', 'audio', 'audio_filt'};
p.files.delete_fields = {'current', 'length', 'frequency', 'amplitude'};

p.files.save_folder = ['./data/processed/' p.files.group '/' p.files.bird_name ];
p.files.save.save_prefix = [p.files.save_folder '/' p.files.bird_name];

%--save files
% empty array to skip saving
p.files.save.unproc_save_file   = [];
p.files.save.proc_save_file     = [];
p.files.save.call_seg_save_file = [];
p.files.save.call_breath_seg_save_file = [p.files.save.save_prefix '-data.mat'];
p.files.save.parameter_save_file = [p.files.save.save_prefix '-parameters.mat'];
% p.files.save.breathing_audio_save_file = [p.files.save.save_prefix '-breathing_audio.mat'];  % savefile for breathing & audio separately without analyzed data
p.files.save.breathing_audio_save_file = [];  % savefile for breathing & audio separately without analyzed data


p.files.figure_folder = ['./data/figures/' p.files.group ];

p.files.to_plot = {'exp', 'aud', 'insp', 'breath_trace', 'breath_trace_insp'};  % figure types to plot for this bird (see `./automated_pipeline/plot`)
p.files.save.figure_prefix = [p.files.figure_folder '/' p.files.bird_name '-'];  % filename prefix to save figures for this bird
p.files.save.fig_extension = 'svg';

%--windowing
p.window.radius_seconds = 1.5;  % for each window, time before and after stim (seconds). usually 1s, for total window length of 2s 
p.window.stim_i = p.window.radius_seconds * p.fs + 1;  % stimulation onset frame index
p.window.stim_cooldown = 100; % ignore a stim if another stim has occured within the last (cooldown) frames (eg, stim flickers for 10 frames)

%--breathing filter parameters
p.filt_breath.type = 'lowpassfir';
p.filt_breath.FilterOrder = 30;
p.filt_breath.PassbandFrequency = 400;
p.filt_breath.StopbandFrequency = 450;


%--audio filtering/smoothing options
p.audio_filt_smooth.f_low = 500;
p.audio_filt_smooth.f_high = 10000;
p.audio_filt_smooth.smooth_window_ms = 2.0; % ms
p.audio_filt_smooth.filt_type = 'butterworth';

%% most likely to vary between birds

%--call segmentation options
p.call_seg.q = 5;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 30;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 10;  % ms; minimum duration of note to be considered (else ignored)

p.call_seg.post_stim_call_window_ii = ([10 350] * p.fs/1000)+p.window.stim_i;  % only check for call trial within this window after stim onset

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;  % min time (FRAMES) between 2 insps/2exps
p.breath_seg.exp_thresh = 0.03;
p.breath_seg.insp_thresh = -0.03;

% time (ms) before/after stim to consider breaths pre/post/peri-stimulus.
p.breath_seg.stim_window.pre_stim_ms  = 0;  % 0ms
p.breath_seg.stim_window.post_stim_ms = 10;  % 10ms

% stim-induced inspirations
p.breath_seg.stim_induced_insp_window_ms = 35; % window after stimulation to check for inspiration onset (milliseconds).
p.breath_seg.derivative_smooth_window_ms = 50; % number of frames to smooth 1st/2nd derivatives, for inspiratory onset

end