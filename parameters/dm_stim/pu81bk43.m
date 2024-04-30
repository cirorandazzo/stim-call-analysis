%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = './data/dm/DMStim_pu81bk43.mat';
mat_file = true;

p.files.bird_name = 'pu81bk43';
p.files.group = 'dm';


p.fs = 30000;

p = default_params(p);

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.003;
p.breath_seg.insp_thresh = -0.003;




