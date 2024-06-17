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




