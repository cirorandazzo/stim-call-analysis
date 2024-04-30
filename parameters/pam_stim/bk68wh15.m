%% PARAMETERS
% all processing parameters saved in one big struct for ease of
% saving/loading parameters

%--files
p.files.raw_data = './data/pam/bk68wh15';
mat_file = 0;

p.files.bird_name = 'bk68wh15';
p.files.group = 'pam';


p.fs = 30000;


%--save files
% empty array to skip saving
% p.files.save.unproc_save_file   = [save_prefix '_unproc.mat'];
% p.files.save.proc_save_file     = [save_prefix '_proc.mat'];
% p.files.save.call_seg_save_file = [save_prefix '_callseg.mat'];
% p.files.save.call_breath_seg_save_file = [save_prefix '_breathseg.mat'];

p.files.save.unproc_save_file   = [];
p.files.save.proc_save_file     = [];
p.files.save.call_seg_save_file = [];
p.files.save.call_breath_seg_save_file = [];


p = default_params(p);

%--breath segmentation
p.breath_seg.min_duration_fr = 10 * p.fs / 1000;
p.breath_seg.exp_thresh = 0.001;
p.breath_seg.insp_thresh = -0.001;




