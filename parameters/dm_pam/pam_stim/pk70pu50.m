%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters

%--files
p.files.raw_data = '/Volumes/PlasticBag/ziggy/stim_data-20240604/pam/pk70pu50';

p.files.bird_name = 'pk70pu50';
p.files.group = 'pam';

p.fs = 30000;

p = default_params(p);

%--noise thresholding options
p.call_seg.q = 3;  % threshold = p.call_seg.q*MEDIAN
p.call_seg.min_interval_ms = 30;  % ms; minimum time between 2 notes to be considered separate notes (else merged)
p.call_seg.min_duration_ms = 10;  % ms; minimum duration of note to be considered (else ignored)

% reject 1 trial with noise at 195ms (usual range: 10-350ms)
p.call_seg.post_stim_call_window_ms = [10 190];

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.01;
p.breath_seg.insp_thresh = -0.03;




