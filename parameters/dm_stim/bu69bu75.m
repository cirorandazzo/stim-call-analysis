%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = './data/dm/DMStim_bu69bu75.mat';
mat_file = true;

p.files.bird_name = 'bu69bu75';
p.files.group = 'dm';

p.fs = 30000;

p = default_params(p);

% make sure to keep these after default_params so they're not overwritten

%--noise thresholding options
p.call_seg.q = 4;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 30;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 7;  % ms; minimum duration of note to be considered (else ignored)

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.01;
p.breath_seg.insp_thresh = -0.03;




