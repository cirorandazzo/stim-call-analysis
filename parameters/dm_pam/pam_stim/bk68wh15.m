%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters

%--files
p.files.raw_data = 'F:\ziggy\stim_data-20240604\pam\bk68wh15';

p.files.bird_name = 'bk68wh15';
p.files.group = 'pam';


p.fs = 30000;

p = default_params(p);

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.001;
p.breath_seg.insp_thresh = -0.001;




