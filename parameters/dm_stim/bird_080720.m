%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters
% 
% NOTE: saved as bird_080720 since eval('080720') --> int


%--files
p.files.raw_data = './data/dm/DMStim_080720.mat';
mat_file = true;

p.files.bird_name = '080720';
p.files.group = 'dm';


p.fs = 30000;

p = default_params(p);

% make sure to keep these after default_params so they're not overwritten

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.001;
p.breath_seg.insp_thresh = -0.003;


%--noise thresholding options
p.call_seg.q = 1.5;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 10;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 10;  % ms; minimum duration of note to be considered (else ignored)
