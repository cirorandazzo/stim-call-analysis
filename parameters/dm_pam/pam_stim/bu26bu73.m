%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters

%--files
p.files.raw_data = 'F:\ziggy\stim_data-20240604\pam\bu26bu73';

p.files.bird_name = 'bu26bu73';
p.files.group = 'pam';

p.fs = 30000;

p.files.parameter_names = {"depth", [], "frequency", "length", "current", [], []};

p = default_params(p);

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.01;
p.breath_seg.insp_thresh = -0.03;

%--call segmentation options
p.call_seg.q = 1.8;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 5;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 7;  % ms; minimum duration of note to be considered (else ignored)1


