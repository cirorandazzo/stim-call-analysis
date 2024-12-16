%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters


%--files
p.files.raw_data = '/Volumes/PlasticBag/ziggy/stim_data-20240604/dm/DMStim_pu81bk43.mat';

p.files.bird_name = 'pu81bk43';
p.files.group = 'dm';

p.fs = 30000;

p = default_params(p);

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.003;
p.breath_seg.insp_thresh = -0.003;

% CLEAR VALUES OF SUBFIELDS
p = clear_manual_fields(p, "call_seg");

% MANUAL FILEPATH
p.call_seg.manual_filepath = '/Volumes/PlasticBag/ziggy/stim_data-20240604/dm/DMStim_pu81bk43-manual_segmentation.mat';
