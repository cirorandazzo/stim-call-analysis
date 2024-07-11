%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = 'F:\ziggy\stim_data-20240604\dm\DMStim_pk30gr9.mat';

p.files.bird_name = 'pk30gr9';
p.files.group = 'dm';

p.fs = 30000;

p = default_params(p);

%--call segmentation options
p.call_seg.q = 3;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 40;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 10;  % ms; minimum duration of note to be considered (else ignored)