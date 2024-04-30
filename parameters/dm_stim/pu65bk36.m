%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = './data/dm/DMStim_pu65bk36.mat';
mat_file = true;

p.files.bird_name = 'pu65bk36';
p.files.group = 'dm';




p.fs = 30000;





p = default_params(p);


%--noise thresholding options
p.call_seg.q = 2.5;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 10;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 10;  % ms; minimum duration of note to be considered (else ignored)

