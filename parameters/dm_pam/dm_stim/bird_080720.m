%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters
% 
% NOTE: saved as bird_080720 since eval('080720') --> int


%--files
p.files.raw_data = '/Volumes/PlasticBag/ziggy/stim_data-20240604/dm/DMStim_080720.mat';

p.files.bird_name = '080720';
p.files.group = 'dm';


p.fs = 30000;

p = default_params(p);

% make sure to keep these after default_params so they're not overwritten

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.001;
p.breath_seg.insp_thresh = -0.003;

% CLEAR VALUES OF SUBFIELDS
p = clear_manual_fields(p, "call_seg");

% MANUAL FILEPATH
p.call_seg.manual_filepath = '/Volumes/PlasticBag/ziggy/stim_data-20240604/dm/DMStim_080720-manual_segmentation.mat';
