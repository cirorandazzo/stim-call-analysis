%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = 'C:\Users\ciro\Documents\code\stim-call-analysis\parameters\hvc_pharmacology\bu69bu75.csv';

p.files.bird_name = 'bu69bu75';

p.fs = 30000;

p = default_params(p);


%--call segmentation options
% defaults neglect some low-amplitude calls
p.call_seg.q = 4;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 30;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 10;  % ms; minimum duration of note to be considered (else ignored)