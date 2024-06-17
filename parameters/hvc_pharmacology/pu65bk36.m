%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = 'C:\Users\ciro\Documents\code\stim-call-analysis\parameters\hvc_pharmacology\pu65bk36.csv';

p.files.bird_name = 'pu65bk36';

p.fs = 30000;

p = default_params(p);

p.files.delete_fields = 'duration';

%--noise thresholding options
% p.call_seg.q = 2.5;  % threshold = p.call_seg.q*MEDIAN
% p.call_seg.min_interval_ms = 10;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
% p.call_seg.min_duration_ms = 10;  % ms; minimum duration of note to be considered (else ignored)

